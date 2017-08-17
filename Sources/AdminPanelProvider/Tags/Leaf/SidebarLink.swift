import Leaf
import Vapor

public final class SidebarLink: BasicTag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "sidebar:link"

    public func run(arguments: ArgumentList) throws -> Node? {
        guard arguments.count >= 2 else {
            throw Error.invalidSyntax("sidebar:link parse error: expected #sidebar:link(title, path, <icon>)")
        }

        guard let title = arguments[0]?.string else {
            throw Error.invalidSyntax("sidebar:link parse error: expected a valid title")
        }

        guard let path = arguments[1]?.string else {
            throw Error.invalidSyntax("sidebar:link parse error: expected a valid path")
        }

        var link = "<li class=\"\"><a href=\"\(path)\">"

        if let icon = arguments[2]?.string {
            link.append("<i class=\"fa fa-\(icon)\"></i> ")
        }

        link.append("\(title)</a></li>")

        return .bytes(link.makeBytes())
    }
}

