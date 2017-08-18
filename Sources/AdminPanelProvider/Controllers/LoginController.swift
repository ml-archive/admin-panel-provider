import Vapor

public final class LoginController {
    public let renderer: ViewRenderer

    public init(renderer: ViewRenderer) {
        self.renderer = renderer
    }

    public func landing(req: Request) throws -> ResponseRepresentable {
        return try renderer.make("Login/index", ["collapse": "true"], for: req)
    }

    public func dashboard(req: Request) throws -> ResponseRepresentable {
        return try renderer.make("Dashboard/index", for: req)
    }
}
