import HTTP
import Vapor

public enum Middlewares {
    public static var unsecured: [Middleware] = []
    public static var secured: [Middleware] = []
}

public class FieldsetMiddleware: Middleware {
    let key = "_fieldset"
    public init() {}

    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        // Add fieldset to next request
        request.storage[key] = request.session?.data[key]
        request.session?.data[key] = nil

        let respond = try next.respond(to: request)
        request.session?.data[key] = respond.storage[key] as? Node ?? nil
        return respond
    }
}
