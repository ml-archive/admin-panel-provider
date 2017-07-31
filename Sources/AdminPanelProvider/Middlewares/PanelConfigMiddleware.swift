import Vapor

public final class PanelConfigMiddleware: Middleware {
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

    public var config: Node

    init(panelName: String, skin: Skin) throws {
        config = try Node(node: [
            "name": panelName,
            "skin": skin.cssClass
        ])
    }

    public func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        request.storage["adminPanel"] = config
        return try next.respond(to: request)
    }
}
