import Leaf
import Vapor

public final class SidebarHeader: BasicTag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "sidebar:header"

    public func run(arguments: ArgumentList) throws -> Node? {
        guard let title = arguments[0]?.string else {
            throw Error.invalidSyntax("sidebar:header parse error: expected a title")
        }

        let header = "<li class=\"header\">\(title)</li>".makeBytes()

        return .bytes(header)
    }
}
