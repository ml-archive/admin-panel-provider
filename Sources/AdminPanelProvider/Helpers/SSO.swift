import Vapor
import AuthProvider

public struct SSOConfig {
    public let environment: Environment
    public let loginPath: String
    public let redirectUrl: String
    public let salt: String
    public let callbackPath: String

    public init(
        environment: Environment,
        loginPath: String,
        redirectUrl: String,
        salt: String,
        callbackPath: String
    ) {
        self.environment = environment
        self.loginPath = loginPath
        self.redirectUrl = redirectUrl
        self.salt = salt
        self.callbackPath = callbackPath
    }

    public init(_ config: Config) throws {
        let environment = config.environment

        guard let config = config["adminpanel-sso-nodes"] else {
            throw ConfigError.missingFile("adminpanel-sso-nodes.json")
        }

        guard let redirectUrl = config["redirectUrl"]?.string else {
            throw ConfigError.missing(key: ["redirectUrl"], file: "adminpanel-sso-nodes.json", desiredType: String.self)
        }

        guard let salt = config["salt"]?.string else {
            throw ConfigError.missing(key: ["salt"], file: "adminpanel-sso-nodes.json", desiredType: String.self)
        }

        let callbackPath = config["callbackPath"]?.string ?? "/admin/manager_auth"
        let loginPath = config["loginPath"]?.string ?? "/admin/sso/login"

        self.init(
            environment: environment,
            loginPath: loginPath,
            redirectUrl: redirectUrl,
            salt: salt,
            callbackPath: callbackPath
        )
    }
}

public final class SSOProvider: Vapor.Provider {
    public static let repositoryName = "nodes-vapor/admin-panel-sso-nodes-provider"
    public var config: SSOConfig!

    public init() {}

    public convenience init(config: Config) throws {
        self.init()
    }

    public func boot(_ config: Config) throws {
        self.config = try SSOConfig(config)

        let middleware = SSONodesMiddleware(loginPath: self.config.loginPath)
        Middlewares.unsecured.append(middleware)
    }

    public func boot(_ droplet: Droplet) throws {
        let hasher = CryptoHasher(hash: .sha256, encoding: .hex)
        let controller = SSOController(
            environment: config.environment,
            hasher: hasher,
            salt: config.salt,
            callbackPath: config.callbackPath,
            redirectUrl: config.redirectUrl
        )
        let ssoRoutes = SSONodesRoutes(
            loginPath: config.loginPath,
            callbackPath: config.callbackPath,
            controller: controller
        )

        try droplet.collection(ssoRoutes)
    }

    public func beforeRun(_ droplet: Droplet) throws {}
}

public final class SSONodesMiddleware: Middleware {
    private let loginPath: String

    public init(loginPath: String) {
        self.loginPath = loginPath
    }

    public func respond(
        to request: Request,
        chainingTo next: Responder
    ) throws -> Response {
        guard
            var adminPanel = request.storage["adminPanel"] as? Node,
            var sso = adminPanel["sso"]?.object
        else {
            throw Abort(.badGateway)
        }

        sso["nodes"] = try Node(node: ["loginPath": loginPath])
        adminPanel["sso"] = Node(sso)
        request.storage["adminPanel"] = adminPanel
        return try next.respond(to: request)
    }
}

public final class SSOController {
    private let environment: Environment
    private let hasher: CryptoHasher
    private let salt: String
    private let callbackPath: String
    private let redirectUrl: String

    public init(
        environment: Environment,
        hasher: CryptoHasher,
        salt: String,
        callbackPath: String,
        redirectUrl: String
    ) {
        self.environment = environment
        self.hasher = hasher
        self.salt = salt
        self.callbackPath = callbackPath
        self.redirectUrl = redirectUrl
    }

    public func auth(req: Request) throws -> Response {
        // skip SSO on local environments
        if isLocalEnvironment() || req.uri.hostname.isLocalhost {
            guard let user = try User.makeQuery().first() else {
                throw Abort(.internalServerError, reason: "No backend users exist. Try running `admin-panel:seeder`")
            }

            req.auth.authenticate(user)
            return redirect("/admin/dashboard").flash(.success, "Logged in as \(user.email)")
        }

        let resultingPath = req.uri.scheme + "://" + req.uri.hostname + callbackPath
        return redirect(redirectUrl + "?redirect_url=" + resultingPath)
    }

    public func callback(req: Request) throws -> ResponseRepresentable {
        guard
            let token = req.data["token"]?.string,
            let email = req.data["email"]?.string
        else {
            return redirect("/admin/login").flash(.error, "Missing token")
        }

        let salt = self.salt.replacingOccurrences(of: "#email", with: email)
        let validToken = try hasher.make(salt).makeString()

        if token != validToken {
            return redirect("/admin/login").flash(.error, "Token did not match. Try again")
        }

        let user: User
        if let existing = try User.makeQuery().filter("email", email).first() {
            user = existing
        } else {
            user = try User(
                name: "Admin",
                title: "Nodes Admin",
                email: email,
                password: String.random(16),
                role: "Super Admin",
                shouldResetPassword: false,
                avatar: nil
            )

            try user.save()
        }

        req.auth.authenticate(user)
        return redirect("/admin/dashboard").flash(.success, "Logged in as \(user.email)")
    }

    // MARK: Helpers

    private func isLocalEnvironment() -> Bool {
        return self.environment == Environment.custom("local")
    }
}

public final class SSONodesRoutes: RouteCollection {
    private let loginPath: String
    private let callbackPath: String
    private let controller: SSOController

    public init(
        loginPath: String,
        callbackPath: String,
        controller: SSOController
    ) {
        self.loginPath = loginPath
        self.callbackPath = callbackPath
        self.controller = controller
    }

    public func build(_ builder: RouteBuilder) throws {
        builder.group(middleware: Middlewares.unsecured) { unsecured in
            unsecured.get(loginPath, handler: controller.auth)
            unsecured.post(callbackPath, handler: controller.callback)
        }
    }
}
