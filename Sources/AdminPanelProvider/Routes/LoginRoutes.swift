import HTTP
import Vapor
import AuthProvider

public final class LoginRoutes: RouteCollection {
    public let renderer: ViewRenderer

    public init(renderer: ViewRenderer) {
        self.renderer = renderer
    }

    public func build(_ builder: RouteBuilder) throws {
        let controller = LoginController(renderer: renderer)

        builder.group(middleware: Middlewares.unsecured) { unsecured in
            builder.get(handler: controller.landing)
            builder.get("/admin/login", handler: controller.landing)
        }

        builder.group(middleware: Middlewares.unsecured) { secured in
            secured.post("/admin/login", handler: controller.login)
        }
    }
}
