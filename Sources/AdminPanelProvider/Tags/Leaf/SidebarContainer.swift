import Leaf
import Vapor

public final class SidebarContainer: Tag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "sidebar:container"

    public func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard arguments.count >= 1 else {
            throw Error.invalidSyntax("sidebar:container parse error: expected #sidebar:link(title, <icon>)")
        }

        guard let title = arguments[0]?.string else {
            throw Error.invalidSyntax("sidebar:link parse error: expected a valid title")
        }

        let path = arguments.extractPath()
        let isActive = Request.isActive(path, nil, arguments.list.dropFirst(), arguments.stem, arguments.context)

        var link = "<li class=\"treeview\(isActive ? " active menu-open" : "")\"><a href=\"#\">"

        if let icon = arguments[2]?.string {
            link.append("<i class=\"\(icon)\"></i> ")
        }

        link.append("<span>\(title)</span><span class=\"pull-right-container\"><i class=\"fa fa-angle-left pull-right\"></i></span></a><ul class=\"treeview-menu\">")

        return .bytes(link.makeBytes())
    }

    public func render(stem: Stem, context: LeafContext, value: Node?, leaf: Leaf) throws -> Bytes {
        guard var body = value?.bytes else {
            throw Abort.serverError
        }

        try body.append(contentsOf: stem.render(leaf, with: context))
        body.append(contentsOf: "</ul></li>".makeBytes())
        return body
    }
}
