import HTTP
import Flash
import Authentication

public typealias ProtectMiddleware = CustomUserProtectMiddleware<AdminPanelUser>

/// Redirects unauthenticated requests to a supplied path.
public final class CustomUserProtectMiddleware<U: AdminPanelUserType>: Middleware {
    let passwordEditPathForUser: (U) -> String
    init(passwordEditPathForUser: @escaping (U) -> String) {
        self.passwordEditPathForUser = passwordEditPathForUser
    }

    public func respond(to req: Request, chainingTo next: Responder) throws -> Response {
        do {
            if let user: U = req.auth.authenticated(), user.shouldResetPassword {
                let redirectPath = passwordEditPathForUser(user)

                if req.uri.path != redirectPath && req.uri.path.replacingOccurrences(of: "/", with: "") != redirectPath.replacingOccurrences(of: "/", with: "") {
                    return redirect(redirectPath).flash(.error, "Please update your password")
                }
            }

            return try next.respond(to: req)
        } catch is AuthenticationError {
            return redirect("/admin/login?next=\(req.uri.path)")
        }
    }
}
