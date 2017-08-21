import Vapor
import AuthProvider

public final class SSO: ConfigInitializable {
    let isLocalEnvironment: Bool
    let redirectUrl: String
    let salt: String
    let callbackPath: String
    let hasher = CryptoHasher(hash: .sha256, encoding: .hex)

    public init(
        isLocalEnvironment: Bool,
        redirectUrl: String,
        salt: String,
        callbackPath: String
    ) {
        self.isLocalEnvironment = isLocalEnvironment
        self.redirectUrl = redirectUrl
        self.salt = salt
        self.callbackPath = callbackPath
    }
}

extension SSO {
    public func auth(req: Request) throws -> Response {
        // skip SSO on local environments
        if isLocalEnvironment || req.uri.hostname.isLocalhost {
            guard let user = try BackendUser.makeQuery().first() else {
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

        let user: BackendUser
        if let existing = try BackendUser.makeQuery().filter("email", email).first() {
            user = existing
        } else {
            user = try BackendUser(
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
}

extension SSO {
    public convenience init(config: Config) throws {
        let env = config.environment
        let isLocalEnvironment = env == Environment.custom("local")

        guard let config = config["sso"] else {
            throw ConfigError.missingFile("sso.json")
        }

        guard let redirectUrl = config["redirectUrl"]?.string else {
            throw ConfigError.missing(key: ["redirectUrl"], file: "sso.json", desiredType: String.self)
        }

        guard let salt = config["salt"]?.string else {
            throw ConfigError.missing(key: ["salt"], file: "sso.json", desiredType: String.self)
        }

        guard let callbackPath = config["callbackPath"]?.string else {
            throw ConfigError.missing(key: ["callbackPath"], file: "sso.json", desiredType: String.self)
        }

        self.init(
            isLocalEnvironment: isLocalEnvironment,
            redirectUrl: redirectUrl,
            salt: salt,
            callbackPath: callbackPath
        )
    }
}
