import HTTP
import Vapor

public typealias AdminPanelUserRoutes = CustomAdminPanelUserRoutes<AdminPanelUser>

public final class CustomAdminPanelUserRoutes<U: AdminPanelUserType>: RouteCollection {
    public let controller: CustomAdminPanelUserController<U>

    public init(
        renderer: ViewRenderer,
        env: Environment,
        mailer: MailProtocol?,
        panelConfig: PanelConfig
    ) {
        controller = CustomAdminPanelUserController<U>(
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

        admin.get("backend/users/", U.parameter, "edit", handler: controller.edit)
        admin.post("backend/users/", U.parameter, "edit", handler: controller.update)

        admin.post("backend/users/", U.parameter, "delete", handler: controller.delete)
        admin.get("backend/users/", Int.parameter, "restore", handler: controller.restore)

        admin.get("backend/users/logout", handler: controller.logout)
    }
}
