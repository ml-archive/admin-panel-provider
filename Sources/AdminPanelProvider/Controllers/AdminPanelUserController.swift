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
        let requestingUser: U = try req.auth.assertAuthenticated()
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
        let requestingUser: U = try req.auth.assertAuthenticated()
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)
        let fieldset = try req.fieldset ?? AdminPanelUserForm().makeFieldset(inValidationMode: .none)

        return try renderer.make(
            "AdminPanel/BackendUser/edit",
            ViewData([.fieldset: fieldset, .request: req])
        )
    }

    public func store(req: Request) throws -> ResponseRepresentable {
        let requestingUser: U = try req.auth.assertAuthenticated()
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)

        do {
            let form = try U.Form.init(request: req)

            guard form.isValid(inValidationMode: .all) else {
                return try redirect("/admin/backend/users/create")
                    .flash(.error, "Validation error")
                    .setFieldset(form.makeFieldset(inValidationMode: .all))
            }

            guard let role = form.role, Gate.allow(requestingUser.role, requiredRole: role) else {
                return try redirect("/admin/backend/users/create")
                    .flash(.error, "Cannot create user with higher role than yourself.")
                    .setFieldset(form.makeFieldset(inValidationMode: .all))
            }

            let user = try U.init(
                form: form,
                panelConfig: panelConfig,
                req: req
            )

            var randomPassword: String?
            if form.password == nil || form.password?.isEmpty == true {
                randomPassword = String.random(12)
                user.password = try U.hashPassword(randomPassword!) // safe to force unwrap here
            }

            try user.save()

            if
                form.shouldSendEmail ?? false,
                panelConfig.isEmailEnabled,
                let name = panelConfig.fromName,
                let email = panelConfig.fromEmail
            {
                var context: ViewData = try [
                    "user": user.makeViewData(),
                    "name": .string(name),
                    "url": .string(panelConfig.baseUrl)
                ]

                if let randomPassword = randomPassword {
                    context["password"] = .string(randomPassword)
                }

                mailer?.sendEmail(
                    from: EmailAddress(name: name, address: email),
                    to: user,
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
            user = try req.parameters.next()
        } catch {
            return redirect("/admin/backend/users").flash(.error, "User not found")
        }

        let requestingUser: U = try req.auth.assertAuthenticated()
        let allowed = requestingUser.id == user.id ||
            Gate.allow(requestingUser.role, requiredRole: user.role) &&
            Gate.allow(requestingUser, requiredRole: .admin)


        guard allowed else {
            throw Abort.notFound
        }

        let fieldset = try req.fieldset ?? user.makeForm().makeFieldset(inValidationMode: .none)
        return try renderer.make(
            "AdminPanel/BackendUser/edit",
            ViewData(["user": user, .fieldset: fieldset, .request: req])
        )
    }

    public func update(req: Request) throws -> ResponseRepresentable {
        do {
            var user: U
            do {
                user = try req.parameters.next()
            } catch {
                return redirect("/admin/backend/users").flash(.error, "User not found")
            }

            let requestingUser: U = try req.auth.assertAuthenticated()
            let allowed = requestingUser.id == user.id ||
                Gate.allow(requestingUser.role, requiredRole: user.role) &&
                Gate.allow(requestingUser, requiredRole: .admin)

            guard allowed else {
                throw Abort.notFound
            }

            let form = try U.Form.init(request: req)

            if !form.isValid(inValidationMode: .nonNil) {
                return redirect("/admin/backend/users/\(user.id?.string ?? "0")/edit/")
                    .flash(.error, "Validation error")
                    .setFieldset(try form.makeFieldset(inValidationMode: .nonNil))
            }

            // Users aren't allowed to change their own role
            if let role = form.role, requestingUser.id != user.id {
                // is the requesting user allowed to select this role?
                if Gate.allow(requestingUser.role, requiredRole: role) {
                    user.role = role
                }
            }

            try user.updateNonPasswordValues(form: form, panelConfig: panelConfig, req: req)

            let passwordHash = try form.password.map(U.hashPassword)

            if user.shouldResetPassword, passwordHash == user.password || passwordHash == nil {
                return try redirect("/admin/backend/users/\(user.id?.string ?? "0")/edit/")
                    .flash(.error, "Please pick a new password")
                    .setFieldset(form.makeFieldset(inValidationMode: .nonNil))
            }

            if let passwordHash = passwordHash {
                user.password = passwordHash
                user.shouldResetPassword = false
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
        let requestingUser: U = try req.auth.assertAuthenticated()
        try Gate.assertAllowed(requestingUser, requiredRole: .admin)

        let user: U
        do {
            user = try req.parameters.next()
        } catch {
            return redirect("/admin/backend/users").flash(.error, "User not found")
        }

        guard user.id != requestingUser.id else {
            return redirect("/admin/backend/users").flash(.error, "Cannot delete yourself")
        }

        let allowed =
            Gate.allow(requestingUser.role, requiredRole: user.role) &&
            Gate.allow(requestingUser, requiredRole: .admin)
        guard allowed else {
            return redirect("/admin/backend/users")
                .flash(.error, "Cannot delete user with a higher role.")
        }

        try user.delete()

        return redirect("/admin/backend/users").flash(.warning, "User has been deleted. <a href='/admin/backend/users/\(user.id?.string ?? "0")/restore'>Undo</a>")
    }

    public func restore(req: Request) throws -> ResponseRepresentable {
        let requestingUser: U = try req.auth.assertAuthenticated()
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
