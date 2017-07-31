import Leaf
import Vapor

public final class SolidBox: Tag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "solidbox"

    public func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        let title = arguments[0]?.string
        let type = arguments[1]?.string ?? "default"
        var header = "<div class=\"box box-solid box-\(type)\">".makeBytes()
        if let title = title {
            header.append(contentsOf: "<div class=\"box-header with-border\"><h3 class=\"box-title\">\(title)</h3></div>".makeBytes())
        }

        header.append(contentsOf: "<div class=\"box-body\">".makeBytes())

        return .bytes(header)
    }

    public func render(stem: Stem, context: LeafContext, value: Node?, leaf: Leaf) throws -> Bytes {
        guard var body = value?.bytes else {
            throw Abort.serverError
        }

        try body.append(contentsOf: stem.render(leaf, with: context))
        body.append(contentsOf: "</div></div>".makeBytes())
        return body
    }
}

