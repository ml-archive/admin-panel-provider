import HTTP
import Vapor

public final class PanelRoutes: RouteCollection {
    public let controller: LoginController

    public init(renderer: ViewRenderer, mailgun: Mailgun?, panelConfig: PanelConfig) {
        controller = LoginController(renderer: renderer, mailgun: mailgun, panelConfig: panelConfig)
    }

    public func build(_ builder: RouteBuilder) throws {
        let admin = builder.grouped("admin").grouped(Middlewares.secured)
        admin.get("dashboard", handler: controller.dashboard)
    }
}
