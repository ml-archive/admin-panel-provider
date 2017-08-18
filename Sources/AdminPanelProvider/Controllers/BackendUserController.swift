import Flash
import Vapor

public final class BackendUserController {
    public let renderer: ViewRenderer
    public let env: Environment
    public let isEmailEnabled: Bool
    public let isStorageEnabled: Bool

    public init(
        renderer: ViewRenderer,
        env: Environment,
        isEmailEnabled: Bool,
        isStorageEnabled: Bool
    ) {
        self.renderer = renderer
        self.env = env
        self.isEmailEnabled = isEmailEnabled
        self.isStorageEnabled = isStorageEnabled
    }

    public func index(req: Request) throws -> ResponseRepresentable {
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
        let fieldset = try req.storage["_fieldset"] as? Node ??  BackendUserForm().makeNode(in: nil)
        return try renderer.make("BackendUser/edit", ["roles": BackendUser.roles, "fieldset": fieldset], for: req)
    }

    public func store(req: Request) throws -> ResponseRepresentable {
        do {
            let (form, hasErrors) = BackendUserForm.validating(req.data)
            if hasErrors {
                let response = redirect("/admin/backend/users/create").flash(.error, "Validation error")
                let fieldset = try form.makeNode(in: nil)
                response.storage["_fieldset"] = fieldset
                return response
            }

            let user = try BackendUser(
                name: form.name,
                title: form.title,
                email: form.email,
                password: form.password,
                role: form.role,
                shouldResetPassword: form.shouldResetPassword,
                // TODO: image uploads
                avatar: nil
            )
            try user.save()

            if form.sendEmail, isEmailEnabled {
                // TODO: send emails
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
            // TODO: redirect back to where user came from
            return redirect("/admin/backend/users").flash(.error, "User not found")
        }

        let fieldset = try req.storage["_fieldset"] as? Node ??  BackendUserForm().makeNode(in: nil)
        return try renderer.make("BackendUser/edit", ["user": user, "roles": BackendUser.roles,"fieldset": fieldset], for: req)
    }

    public func update(req: Request) throws -> ResponseRepresentable {
        do {
            var user: BackendUser
            do {
                user = try req.parameters.next(BackendUser.self)
            } catch {
                // TODO: redirect back to where user came from
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

            // TODO: image uploads
            user.name = form.name
            user.title = form.title
            user.email = form.email
            user.password = try BCryptHasher().make(form.password.makeBytes()).makeString()
            user.role = form.role
            user.shouldResetPassword = form.shouldResetPassword

            try user.save()
            return redirect("/admin/backend/users").flash(.success, "User has been updated")
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

    public func delete(req: Request) throws -> ResponseRepresentable {
        let user: BackendUser
        do {
            user = try req.parameters.next(BackendUser.self)
        } catch {
            // TODO: redirect back to where user came from
            return redirect("/admin/backend/users").flash(.error, "User not found")
        }

        try user.delete()

        // TODO: redirect back to where user came from
        return redirect("/admin/backend/users").flash(.warning, "User has been deleted. <a href='/admin/backend/users/\(user.id?.int ?? 0)/restore'>Undo</a>")
    }

    public func restore(req: Request) throws -> ResponseRepresentable {
        let user: BackendUser
        do {
            let id = try req.parameters.next(Int.self)
            guard let u = try BackendUser.makeQuery().filter("id", id).withSoftDeleted().first() else {
                throw Abort.notFound
            }

            user = u
        } catch {
            // TODO: redirect back to where user came from
            return redirect("/admin/backend/users").flash(.error, "User not found")
        }

        try user.restore()
        return redirect("/admin/backend/users").flash(.success, "User has been restored")
    }
}
