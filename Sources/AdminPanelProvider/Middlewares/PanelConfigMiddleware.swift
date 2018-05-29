import Fluent
import Storage
import Vapor

/// AdminPanel's configuration
public struct PanelConfig {
    /// Name to use for emails and the site's logo
    public let panelName: String
    /// Base URL of the admin panel
    public let baseUrl: String
    /// AdminLTE skin colour
    public let skin: Skin

    /// If enabled, the admin panel will send an email when new users are created
    /// and when their passwords are reset.
    public let isEmailEnabled: Bool
    /// Sender's email address
    public let fromEmail: String?
    /// Sender's name
    public let fromName: String?

    /// Whether or not Storage (nodes-vapor/storage) is enabled for file uploads
    public let isStorageEnabled: Bool

    internal let passwordEditPathForUser: (Entity) -> String

    public init(
        panelName: String,
        baseUrl: String,
        skin: Skin,
        isEmailEnabled: Bool,
        isStorageEnabled: Bool,
        fromEmail: String?,
        fromName: String?,
        passwordEditPathForUser: @escaping (Entity) -> String
    ) {
        self.panelName = panelName
        self.baseUrl = baseUrl
        self.skin = skin
        self.isEmailEnabled = isEmailEnabled
        self.isStorageEnabled = isStorageEnabled
        self.fromEmail = fromEmail
        self.fromName = fromName
        self.passwordEditPathForUser = passwordEditPathForUser
    }

    /// AdminLTE-supported skins
    public enum Skin: String {
        case blue
        case blueLight = "blue-light"
        case yellow
        case yellowLight = "yellow-light"
        case green
        case greenLight = "green-light"
        case purple
        case purpleLight = "purple-light"
        case red
        case redLight = "red-light"
        case black
        case blackLight = "black-light"

        /// The CSS class name equivalent
        public var cssClass: String {
            return "skin-\(self.rawValue)"
        }
    }
}

extension PanelConfig: ConfigInitializable {
    public init(config: Config) throws {
        try self.init(config: config, passwordEditPathForUser: { user in
            "/admin/backend/users/\(user.id?.string ?? "0")/edit"
        })
    }

    public init(
        config: Config,
        passwordEditPathForUser: @escaping (Entity) -> String
    ) throws {
        var panelName = "Admin Panel"
        var baseUrl = "127.0.0.1:8080"
        var skin: PanelConfig.Skin = .blue
        var isEmailEnabled = true
        var isStorageEnabled = true
        var fromEmail: String?
        var fromName: String?
        let fileName = "adminpanel"

        if let config = config[fileName, "email"] {
            guard let email = config["fromAddress"]?.string else {
                throw ConfigError.missing(
                    key: ["fromAddress"],
                    file: fileName,
                    desiredType: String.self
                )
            }

            guard let name = config["fromName"]?.string else {
                throw ConfigError.missing(
                    key: ["fromName"],
                    file: fileName,
                    desiredType: String.self
                )
            }

            fromEmail = email
            fromName = name
        } else {
            print("WARNING: couldn't find `email` key in `\(fileName).json`. Email features will be disabled.")
            isEmailEnabled = false
        }

        if let config = config[fileName] {
            panelName = config["name"]?.string ?? panelName
            baseUrl = config["baseUrl"]?.string ?? baseUrl

            if let userSkinConfig = config["skin"]?.string {
                skin = PanelConfig.Skin(rawValue: userSkinConfig) ?? skin
            }
        }

        if config["storage"] != nil {
            // only add storage if it hasn't been added yet
            if !config.providers.contains(where: { type(of: $0).repositoryName == "Storage" }) {
                try config.addProvider(StorageProvider.self)
            }
        } else {
            print("WARNING: couldn't find `storage.json`. Image uploads will be disabled.")
            isStorageEnabled = false
        }

        self.init(
            panelName: panelName,
            baseUrl: baseUrl,
            skin: skin,
            isEmailEnabled: isEmailEnabled,
            isStorageEnabled: isStorageEnabled,
            fromEmail: fromEmail,
            fromName: fromName,
            passwordEditPathForUser: passwordEditPathForUser
        )
    }
}

public final class PanelConfigMiddleware: Middleware {
    private let config: PanelConfig

    public init(_ config: PanelConfig) throws {
        self.config = config
    }

    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        var updatedConfig = request.storage["adminPanel"] as? Node ?? Node([:])
        try updatedConfig.set("name", config.panelName)
        try updatedConfig.set("skin", config.skin.cssClass)
        try updatedConfig.set("isEmailEnabled", config.isEmailEnabled)
        try updatedConfig.set("isStorageEnabled", config.isStorageEnabled)

        request.storage["adminPanel"] = updatedConfig
        return try next.respond(to: request)
    }
}

