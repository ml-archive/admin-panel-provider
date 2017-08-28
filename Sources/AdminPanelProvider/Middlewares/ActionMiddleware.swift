import Vapor

public final class ActionMiddleware: Middleware {
    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
//        request.storage["actions"] = Node([
//            Node([
//                "name": "Brett",
//                "userId": 10,
//                "message": "Deleted Steffen's dog's profile."
//            ])
//        ])
//        request.storage["unseenActivities"] = 1
        return try next.respond(to: request)
    }
}
