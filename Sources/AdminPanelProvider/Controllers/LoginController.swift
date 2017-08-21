import Vapor
import AuthProvider

public final class LoginController {
    public let renderer: ViewRenderer

    public init(renderer: ViewRenderer) {
        self.renderer = renderer
    }

    public func login(req: Request) throws -> ResponseRepresentable {
        do {
            guard
                let username = req.data["email"]?.string,
                let password = req.data["password"]?.string
            else {
                return redirect("/admin/login").flash(.error, "Invalid username and/or password")
            }

            let credentials = Password(username: username, password: password)
            let user = try BackendUser.authenticate(credentials)
            req.auth.authenticate(user)

            var redir = "/admin/dashboard"
            if let next = req.query?["next"]?.string, !next.isEmpty {
                redir = next
            }

            return redirect(redir).flash(.success, "Logged in as \(username)")
        } catch {
            return redirect("/admin/login").flash(.error, "Failed to login")
        }
    }

    public func landing(req: Request) throws -> ResponseRepresentable {
        let next = req.query?["next"]

        return try renderer.make(
            "Login/index",
            [
                "collapse": "true",
                "next": next
            ],
            for: req
        )
    }

    public func dashboard(req: Request) throws -> ResponseRepresentable {
        return try renderer.make("Dashboard/index", for: req)
    }
}
