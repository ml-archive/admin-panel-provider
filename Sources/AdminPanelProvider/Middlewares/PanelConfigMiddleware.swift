import Vapor

public struct PanelConfig {
    public let panelName: String
    public let skin: Skin

    public let isEmailEnabled: Bool
    public let isStorageEnabled: Bool

    public init(panelName: String, skin: Skin, isEmailEnabled: Bool, isStorageEnabled: Bool) {
        self.panelName = panelName
        self.skin = skin
        self.isEmailEnabled = isEmailEnabled
        self.isStorageEnabled = isStorageEnabled
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
    public var config: Node

    init(_ config: PanelConfig) throws {
        self.config = try Node(node: [
            "name": config.panelName,
            "skin": config.skin.cssClass,
            "isEmailEnabled": config.isEmailEnabled,
            "isStorageEnabled": config.isStorageEnabled
        ])
    }

    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        request.storage["adminPanel"] = config
        return try next.respond(to: request)
    }
}
