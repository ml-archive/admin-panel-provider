import HTTP
import Vapor

public final class PanelRoutes: RouteCollection {
    public let controller: LoginController

    public init(renderer: ViewRenderer, mailer: MailProtocol?, panelConfig: PanelConfig) {
        controller = LoginController(renderer: renderer, mailer: mailer, panelConfig: panelConfig)
    }

    public func build(_ builder: RouteBuilder) throws {
        let admin = builder.grouped("admin").grouped(Middlewares.secured)
        admin.get("dashboard", handler: controller.dashboard)
    }
}
