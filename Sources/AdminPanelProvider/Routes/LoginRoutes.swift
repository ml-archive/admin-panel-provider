import HTTP
import Vapor

public final class LoginRoutes: RouteCollection {
    public let renderer: ViewRenderer

    public init(renderer: ViewRenderer) {
        self.renderer = renderer
    }

    public func build(_ builder: RouteBuilder) throws {
        let controller = LoginController(renderer: renderer)

        builder.get(handler: controller.landing)
        builder.get("/admin", handler: controller.landing)
    }
}
