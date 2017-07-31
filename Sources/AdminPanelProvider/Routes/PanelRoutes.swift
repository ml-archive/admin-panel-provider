import HTTP
import Vapor

public final class PanelRoutes: RouteCollection {
    public let controller: LoginController

    public init(renderer: ViewRenderer) {
        controller = LoginController(renderer: renderer)
    }

    public func build(_ builder: RouteBuilder) throws {
        let admin = builder.grouped("admin").grouped(Middlewares.secured)
        admin.get("dashboard", handler: controller.dashboard)
    }
}

