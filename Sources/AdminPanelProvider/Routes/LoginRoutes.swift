import HTTP
import Vapor
import AuthProvider

public final class LoginRoutes: RouteCollection {
    public let renderer: ViewRenderer
    public let ssoController: SSO?

    public init(renderer: ViewRenderer, ssoController: SSO?) {
        self.renderer = renderer
        self.ssoController = ssoController
    }

    public func build(_ builder: RouteBuilder) throws {
        let controller = LoginController(renderer: renderer)

        builder.group(middleware: Middlewares.unsecured) { unsecured in
            unsecured.get(handler: controller.landing)
            unsecured.get("/admin", handler: controller.landing)
            unsecured.get("/admin/login", handler: controller.landing)

            if let ssoController = ssoController {
                unsecured.get("/admin/login/sso", handler: ssoController.auth)
                unsecured.post(ssoController.callbackPath, handler: ssoController.callback)
            }
        }

        builder.group(middleware: Middlewares.unsecured) { secured in
            secured.post("/admin/login", handler: controller.login)
        }
    }
}
