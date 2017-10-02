import Vapor

public struct PanelConfig {
    public let panelName: String
    public let baseUrl: String
    public let skin: Skin

    public let isEmailEnabled: Bool
    public let fromEmail: String?
    public let fromName: String?

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
