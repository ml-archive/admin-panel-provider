import Flash
import Forms
import Leaf
import SMTP
import Storage
import Vapor

public typealias AdminPanelUserController = CustomAdminPanelUserController<AdminPanelUser>

public final class CustomAdminPanelUserController<U: AdminPanelUserType> {
    public let renderer: ViewRenderer
    public let env: Environment
    public let mailer: MailProtocol?
    public let panelConfig: PanelConfig

    public init(
        renderer: ViewRenderer,
        env: Environment,
        mailer: MailProtocol?,
        panelConfig: PanelConfig
    ) {
        self.renderer = renderer
        self.env = env
        self.mailer = mailer
        self.panelConfig = panelConfig
    }

    public func index(req: Request) throws -> ResponseRepresentable {
        let requestingUser = try req.auth.assertAuthenticated(U.self)
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)
        let superAdmins = try U.makeQuery().filter(U.roleKey, "Super Admin").all()
        let admins = try U.makeQuery().filter(U.roleKey, "Admin").all()
        let users = try U.makeQuery().filter(U.roleKey, "User").all()

        return try renderer.make(
            "AdminPanel/BackendUser/index",
            [
                "superAdmins": superAdmins,
                "admins": admins,
                "users": users,
            ],
            for: req
        )
    }

    public func create(req: Request) throws -> ResponseRepresentable {
        let requestingUser = try req.auth.assertAuthenticated(U.self)
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)
        let fieldset = try req.fieldset ?? AdminPanelUserForm().makeNode(in: nil)
        return try renderer.make("AdminPanel/BackendUser/edit", ["fieldset": fieldset], for: req)
    }

    public func store(req: Request) throws -> ResponseRepresentable {
        let requestingUser = try req.auth.assertAuthenticated(U.self)
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)

        do {
            let (form, hasErrors) = AdminPanelUserForm.validating(req.data)
            let isEmailUnique = try U.makeQuery().filter("email", form.email).first() == nil

            if hasErrors || !isEmailUnique {
                let response = redirect("/admin/backend/users/create")
                    .flash(.error, "Validation error")
                var fieldset = try form.makeNode(in: nil)

                if (!isEmailUnique) {
                    try fieldset.set(
                        "email",
                        try Node(node: [
                            "label": "Email",
                            "value": .string(form.email),
                            "errors": Node(node: ["Provided email already exists."])
                        ])
                    )
                }

                response.fieldset = fieldset
                return response
            }

            var avatar: String? = nil
            if
                let profileImage = req.data["profileImage"]?.string,
                profileImage.hasPrefix("data:"),
                panelConfig.isStorageEnabled
            {
                let path = try Storage.upload(dataURI: profileImage, folder: "profile")
                avatar = path
            }

            let randomPassword = form.password.isEmpty ? String.random(12) : form.password

            let user = try U(
                name: form.name,
                title: form.title,
                email: form.email,
                password: randomPassword,
                role: form.role,
                shouldResetPassword: form.shouldResetPassword,
                avatar: avatar
            )

            try user.save()

            if
                form.sendEmail,
                panelConfig.isEmailEnabled,
                let name = panelConfig.fromName,
                let email = panelConfig.fromEmail
            {
                var context: ViewData = try [
                    "user": user.makeViewData(),
                    "name": .string(name),
                    "url": .string(panelConfig.baseUrl)
                ]

                if !randomPassword.isEmpty {
                    context["password"] = .string(randomPassword)
                }

                mailer?.sendEmail(
                    from: email,
                    to: user.email,
                    subject: "Welcome to Admin Panel",
                    path: "AdminPanel/Emails/welcome",
                    renderer: renderer,
                    context: context
                )
            }

            return redirect("/admin/backend/users").flash(.success, "Successfully created user")
        } catch {
            let errorMessage: String
            if env == .production {
                errorMessage = "Failed to create user: internal server error."
            } else {
                errorMessage = "Failed to create user: \(error)"
            }

            return redirect("/admin/backend/users/create").flash(.error, errorMessage)
        }
    }

    public func edit(req: Request) throws -> ResponseRepresentable {
        let user: U
        do {
            user = try req.parameters.next(U.self)
        } catch {
            return redirect("/admin/backend/users").flash(.error, "User not found")
        }

        let requestingUser = try req.auth.assertAuthenticated(U.self)
        let allowed = Gate.allow(requestingUser, requiredRole: .admin) || requestingUser.id == user.id

        guard allowed else {
            throw Abort.notFound
        }

        let fieldset = try req.fieldset ?? AdminPanelUserForm().makeNode(in: nil)
        return try renderer.make("AdminPanel/BackendUser/edit", ["user": user, "fieldset": fieldset], for: req)
    }

    public func update(req: Request) throws -> ResponseRepresentable {

        do {
            var user: U
            do {
                user = try req.parameters.next(U.self)
            } catch {
                return redirect("/admin/backend/users").flash(.error, "User not found")
            }

            let requestingUser = try req.auth.assertAuthenticated(U.self)
            let allowed = Gate.allow(requestingUser, requiredRole: .admin) || requestingUser.id == user.id

            guard allowed else {
                throw Abort.notFound
            }

            // users already have a role, so we don't care if they don't/can't update it
            let (form, hasErrors) = AdminPanelUserForm.validating(req.data, ignoreRole: true)

            if
                let userByEmail = try U.makeQuery().filter(U.emailKey, form.email).first(),
                userByEmail.id != user.id
            {
                let response = redirect("/admin/backend/users/\(user.id?.string ?? "0")/edit/")
                    .flash(.error, "Validation error")
                var fieldset = try form.makeNode(in: nil)

                try fieldset.set(
                    "email",
                    try Node(node: [
                        "label": "Email",
                        "value": .string(form.email),
                        "errors": Node(node: ["Provided email already exists."])
                    ])
                )

                response.fieldset = fieldset
                return response
            }

            if hasErrors {
                let response = redirect("/admin/backend/users/\(user.id?.string ?? "0")/edit/")
                    .flash(.error, "Validation error")
                let fieldset = try form.makeNode(in: nil)
                response.fieldset = fieldset
                return response
            }

            user.name = form.name
            user.title = form.title
            user.email = form.email

            let formPasswordHash = try BCryptHasher().make(form.password.makeBytes()).makeString()
            if user.shouldResetPassword {
                guard formPasswordHash != user.password else {
                    let response = redirect("/admin/backend/users/\(user.id?.string ?? "0")/edit/")
                        .flash(.error, "Please pick a new password")
                    let fieldset = try form.makeNode(in: nil)
                    response.fieldset = fieldset
                    return response
                }

                user.shouldResetPassword = false
            }

            if !form.password.isEmpty {
                user.password = formPasswordHash
            }

            // Users aren't allowed to change their own role
            if requestingUser.id != user.id {
                // is the requesting user allowed to select this role?
                if Gate.allow(requestingUser.role, requiredRole: form.role) {
                    user.role = form.role
                }
            }

            if
                let profileImage = req.data["profileImage"]?.string,
                profileImage.hasPrefix("data:"),
                panelConfig.isStorageEnabled
            {
                let path = try Storage.upload(dataURI: profileImage, folder: "profile")
                user.avatar = path
            }

            try user.save()
            return redirect("/admin/backend/users").flash(.success, "User has been updated")
        } catch {
            let errorMessage: String
            if env == .production {
                errorMessage = "Failed to create user: internal server error."
            } else {
                errorMessage = "Failed to create user: \(error)"
            }

            return redirect("/admin/backend/users").flash(.error, errorMessage)
        }
    }

    public func delete(req: Request) throws -> ResponseRepresentable {
        let requestingUser = try req.auth.assertAuthenticated(U.self)
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)

        let user: U
        do {
            user = try req.parameters.next(U.self)
        } catch {
            return redirect("/admin/backend/users").flash(.error, "User not found")
        }

        guard user.id != requestingUser.id else {
            return redirect("/admin/backend/users").flash(.error, "Cannot delete yourself")
        }

        try user.delete()

        return redirect("/admin/backend/users").flash(.warning, "User has been deleted. <a href='/admin/backend/users/\(user.id?.string ?? "0")/restore'>Undo</a>")
    }

    public func restore(req: Request) throws -> ResponseRepresentable {
        let requestingUser = try req.auth.assertAuthenticated(U.self)
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)

        let user: U
        do {
            let id = try req.parameters.next(Int.self)
            guard let u = try U.makeQuery().filter(U.idKey, id).withSoftDeleted().first() else {
                throw Abort.notFound
            }

            user = u
        } catch {
            return redirect("/admin/backend/users").flash(.error, "User not found")
        }

        try user.restore()
        return redirect("/admin/backend/users").flash(.success, "User has been restored")
    }

    public func logout(req: Request) throws -> ResponseRepresentable {
        try req.auth.unauthenticate()
        return redirect("/admin/login").flash(.info, "Logged out")
    }
}
