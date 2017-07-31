import Leaf
import Vapor
import Foundation

public final class MenuFooter: BasicTag {
    public init(){}
    public let name = "menu:footer"

    public func run(arguments: ArgumentList) throws -> Node? {
        guard
            let text = arguments[0]?.string,
            let path = arguments[1]?.string
            else {
                throw Abort(.internalServerError, reason: "menu:toggle parse error: expected `menu:footer(text, path)")
        }

        let template = "<li class=\"footer\"><a href=\"\(path)\">\(text)</a></li>"

        return .bytes(template.makeBytes())
    }
}
