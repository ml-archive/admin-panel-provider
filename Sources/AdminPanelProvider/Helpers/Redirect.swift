import Vapor

/// Syntax sugar for `Response(redirect: path)`
public func redirect(_ path: String) -> Response {
    return Response(redirect: path)
}
