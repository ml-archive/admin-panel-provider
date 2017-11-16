import HTTP
import Vapor

public final class AdminPanelUserRoutes: RouteCollection {
    public let controller: AdminPanelUserController

    public init(
        renderer: ViewRenderer,
        env: Environment,
        mailer: MailProtocol?,
        panelConfig: PanelConfig
    ) {
        controller = AdminPanelUserController(
            renderer: renderer,
            env: env,
            mailer: mailer,
            panelConfig: panelConfig
        )
    }

    public func build(_ builder: RouteBuilder) throws {
        let admin = builder.grouped("admin").grouped(Middlewares.secured)

        admin.get("backend/users", handler: controller.index)

        admin.get("backend/users/create", handler: controller.create)
        admin.post("backend/users/store", handler: controller.store)

        admin.get("backend/users/", AdminPanelUser.parameter, "edit", handler: controller.edit)
        admin.post("backend/users/", AdminPanelUser.parameter, "edit", handler: controller.update)

        admin.get("backend/users/", AdminPanelUser.parameter, "delete", handler: controller.delete)
        admin.get("backend/users/", Int.parameter, "restore", handler: controller.restore)

        admin.get("backend/users/logout", handler: controller.logout)
    }
}
