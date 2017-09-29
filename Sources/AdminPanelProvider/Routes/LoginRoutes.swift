import HTTP
import Vapor
import AuthProvider

public final class LoginRoutes: RouteCollection {
    public let controller: LoginController

    public init(controller: LoginController) {
        self.controller = controller
    }

    public func build(_ builder: RouteBuilder) throws {
        builder.group(middleware: Middlewares.unsecured) { unsecured in
            // General
            unsecured.get(handler: controller.landing)
            unsecured.get("/admin", handler: controller.landing)

            // Login
            unsecured.get("/admin/login", handler: controller.landing)
            unsecured.post("/admin/login", handler: controller.login)

            // Password reset
            unsecured.get("/admin/login/reset", handler: controller.resetPassword)
            unsecured.post("/admin/login/reset", handler: controller.resetPasswordSubmit)
            unsecured.get("/admin/login/reset", String.parameter, handler: controller.resetPasswordToken)
            unsecured.post("/admin/login/reset/change", handler: controller.resetPasswordTokenSubmit)
        }
    }
}
