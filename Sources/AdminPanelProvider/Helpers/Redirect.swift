import Vapor

public func redirect(_ path: String) -> Response {
    return Response(redirect: path)
}
