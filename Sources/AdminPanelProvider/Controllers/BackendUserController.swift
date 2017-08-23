import Leaf
import SMTP
import Flash
import Vapor
import Storage

public final class BackendUserController {
    public let renderer: ViewRenderer
    public let env: Environment
    public let mailgun: Mailgun?
    public let isEmailEnabled: Bool
    public let isStorageEnabled: Bool

    public init(
        renderer: ViewRenderer,
        env: Environment,
        mailgun: Mailgun?,
        isEmailEnabled: Bool,
        isStorageEnabled: Bool
    ) {
        self.renderer = renderer
        self.env = env
        self.mailgun = mailgun
        self.isEmailEnabled = isEmailEnabled
        self.isStorageEnabled = isStorageEnabled
    }

    public func index(req: Request) throws -> ResponseRepresentable {
        let requestingUser = try req.auth.assertAuthenticated(BackendUser.self)
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)
        let superAdmins = try BackendUser.makeQuery().filter("role", "Super Admin").all()
        let admins = try BackendUser.makeQuery().filter("role", "Admin").all()
        let users = try BackendUser.makeQuery().filter("role", "User").all()

        return try renderer.make(
            "BackendUser/index",
            [
                "superAdmins": superAdmins,
                "admins": admins,
                "users": users,
            ],
            for: req
        )
    }

    public func create(req: Request) throws -> ResponseRepresentable {
        let requestingUser = try req.auth.assertAuthenticated(BackendUser.self)
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)
        let fieldset = try req.storage["_fieldset"] as? Node ??  BackendUserForm().makeNode(in: nil)
        return try renderer.make("BackendUser/edit", ["fieldset": fieldset], for: req)
    }

    public func store(req: Request) throws -> ResponseRepresentable {
        let requestingUser = try req.auth.assertAuthenticated(BackendUser.self)
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)

        do {
            let (form, hasErrors) = BackendUserForm.validating(req.data)
            if hasErrors {
                let response = redirect("/admin/backend/users/create").flash(.error, "Validation error")
                let fieldset = try form.makeNode(in: nil)
                response.storage["_fieldset"] = fieldset
                return response
            }

            var avatar: String? = nil
            if let profileImage = req.data["profileImage"]?.string, profileImage.hasPrefix("data:"), isStorageEnabled {
                let path = try Storage.upload(dataURI: profileImage, folder: "profile")
                avatar = path
            }

            let user = try BackendUser(
                name: form.name,
                title: form.title,
                email: form.email,
                password: form.password,
                role: form.role,
                shouldResetPassword: form.shouldResetPassword,
                avatar: avatar
            )
            try user.save()

            if form.sendEmail, isEmailEnabled {
                var context: ViewData = try [
                    "user": user.makeViewData(),
                    "name": "<PLACEHOLDER> TODO"
                ]

                if form.hasRandomPassword {
                    context["password"] = .string(form.password)
                }

                mailgun?.sendEmail(
                    from: "test@tested.com",
                    to: user.email,
                    subject: "Welcome to Admin Panel",
                    path: "Emails/welcome",
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
        let user: BackendUser
        do {
            user = try req.parameters.next(BackendUser.self)
        } catch {
            return redirect("/admin/backend/users").flash(.error, "User not found")
        }

        let requestingUser = try req.auth.assertAuthenticated(BackendUser.self)
        let allowed = Gate.allow(requestingUser, requiredRole: .admin) || requestingUser.id == user.id

        guard allowed else {
            throw Abort.notFound
        }

        let fieldset = try req.storage["_fieldset"] as? Node ??  BackendUserForm().makeNode(in: nil)
        return try renderer.make("BackendUser/edit", ["user": user, "fieldset": fieldset], for: req)
    }

    public func update(req: Request) throws -> ResponseRepresentable {
        let requestingUser = try req.auth.assertAuthenticated(BackendUser.self)
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)

        do {
            var user: BackendUser
            do {
                user = try req.parameters.next(BackendUser.self)
            } catch {
                return redirect("/admin/backend/users").flash(.error, "User not found")
            }

            let (form, hasErrors) = BackendUserForm.validating(req.data)
            if hasErrors {
                // TODO: redirect back to where user came from
                let response = redirect("/admin/backend/users/\(user.id?.int ?? 0)/edit/").flash(.error, "Validation error")
                let fieldset = try form.makeNode(in: nil)
                response.storage["_fieldset"] = fieldset
                return response
            }

            user.name = form.name
            user.title = form.title
            user.email = form.email
            user.password = try BCryptHasher().make(form.password.makeBytes()).makeString()

            // Users aren't allowed to change their own role
            if requestingUser.id != user.id {
                // is the requesting user allowed to select this role?
                if Gate.allow(requestingUser.role, requiredRole: form.role) {
                    user.role = form.role
                }
            }

            user.shouldResetPassword = form.shouldResetPassword

            if let profileImage = req.data["profileImage"]?.string, profileImage.hasPrefix("data:"), isStorageEnabled {
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
        let requestingUser = try req.auth.assertAuthenticated(BackendUser.self)
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)

        let user: BackendUser
        do {
            user = try req.parameters.next(BackendUser.self)
        } catch {
            return redirect("/admin/backend/users").flash(.error, "User not found")
        }

        guard user.id != requestingUser.id else {
            return redirect("/admin/backend/users").flash(.error, "Cannot delete yourself")
        }

        try user.delete()

        return redirect("/admin/backend/users").flash(.warning, "User has been deleted. <a href='/admin/backend/users/\(user.id?.int ?? 0)/restore'>Undo</a>")
    }

    public func restore(req: Request) throws -> ResponseRepresentable {
        let requestingUser = try req.auth.assertAuthenticated(BackendUser.self)
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)

        let user: BackendUser
        do {
            let id = try req.parameters.next(Int.self)
            guard let u = try BackendUser.makeQuery().filter("id", id).withSoftDeleted().first() else {
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
