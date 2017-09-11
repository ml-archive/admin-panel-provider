import HTTP
import Flash
import Authentication

/// Redirects unauthenticated requests to a supplied path.
public final class ProtectMiddleware: Middleware {
    /// The path to redirect to
    public let path: String

    /// Create a new redirect middleware.
    public init(path: String) {
        self.path = path
    }

    public func respond(to req: Request, chainingTo next: Responder) throws -> Response {
        do {
            if let user = req.auth.authenticated(AdminPanelUser.self), user.shouldResetPassword {
                let redirectPath = "/admin/backend/users/\(user.id?.int ?? 0)/edit"

                if req.uri.path != redirectPath && req.uri.path.replacingOccurrences(of: "/", with: "") != redirectPath.replacingOccurrences(of: "/", with: "") {
                    return redirect(redirectPath).flash(.error, "Please update your password")
                }
            }

            return try next.respond(to: req)
        } catch is AuthenticationError {
            return redirect(path + "?next=\(req.uri.path)")
        }
    }

    /// Use this middleware to redirect users away from
    /// protected content to a login page
    public static func login(path: String = "/login") -> ProtectMiddleware {
        return ProtectMiddleware(path: path)
    }
}
