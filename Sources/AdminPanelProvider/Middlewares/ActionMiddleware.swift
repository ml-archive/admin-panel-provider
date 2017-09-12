import Vapor
import Storage
import Paginator
import AuditProvider

public final class ActionMiddleware: Middleware {
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        if request.auth.isAuthenticated(User.self) {
            let node = try AuditEvent.makeQuery().limit(10).all().map { raw -> Node in
                var node = try raw.makeNode(in: nil)

                if let createdAt = raw.createdAt {
                    try node.set("createdAt", createdAt)
                }

                if let author = try User.find(raw.authorId) {
                    try node.set("author", author.makeNode(in: nil))
                }

                return node
            }

            request.storage["actions"] = Node(node)
        }

        return try next.respond(to: request)
    }
}
