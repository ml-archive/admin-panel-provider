import Vapor

/// AdminPanel's configuration
public struct PanelConfig {
    /// Name to use for emails and the site's logo
    public let panelName: String
    /// Base URL of the admin panel
    public let baseUrl: String
    /// AdminLTE skin colour
    public let skin: Skin

    /// Is it?
    public let isEmailEnabled: Bool
    /// Sender's email address
    public let fromEmail: String?
    /// Sender's name
    public let fromName: String?

    /// Whether or not Storage (nodes-vapor/storage) is enabled for file uploads
    public let isStorageEnabled: Bool

    public init(
        panelName: String,
        baseUrl: String,
        skin: Skin,
        isEmailEnabled: Bool,
        isStorageEnabled: Bool,
        fromEmail: String?,
        fromName: String?
    ) {
        self.panelName = panelName
        self.baseUrl = baseUrl
        self.skin = skin
        self.isEmailEnabled = isEmailEnabled
        self.isStorageEnabled = isStorageEnabled
        self.fromEmail = fromEmail
        self.fromName = fromName
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
