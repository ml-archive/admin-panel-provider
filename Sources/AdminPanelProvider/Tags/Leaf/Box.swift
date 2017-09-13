import Leaf
import Vapor

public final class Box: Tag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "box"

    public func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        let title = arguments[0]?.string
        let type = arguments[1]?.string ?? "default"
        var header = "<div class=\"box box-\(type)\">".makeBytes()
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


public final class BoxOpen: BasicTag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "box:open"

    public func run(arguments: ArgumentList) throws -> Node? {
        let title = arguments[0]?.string
        let type = arguments[1]?.string ?? "default"
        let boxType = arguments[2]?.string

        var header = "<div class=\"box \(boxType == nil ? "" : "box-\(boxType!)")box-\(type)\">".makeBytes()
        if let title = title {
            header.append(contentsOf: "<div class=\"box-header with-border\"><h3 class=\"box-title\">\(title)</h3><div class=\"box-tools pull-right\">".makeBytes())
        }

        // TODO
        // Check for body.
        //if arguments.context.queue.tip?.child == nil {
        //    header.append(contentsOf: "</div></div>".makeBytes())
        //}

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

public final class BoxBody: Tag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "box:body"

    public func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        return .bytes("<div class=\"box-body\">".makeBytes())
    }

    public func render(stem: Stem, context: LeafContext, value: Node?, leaf: Leaf) throws -> Bytes {
        guard var body = value?.bytes else {
            throw Abort.serverError
        }

        try body.append(contentsOf: stem.render(leaf, with: context))
        body.append(contentsOf: "</div>".makeBytes())
        return body
    }
}

public final class BoxFooter: Tag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "box:footer"

    public func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        return .bytes("<div class=\"box-footer\">".makeBytes())
    }

    public func render(stem: Stem, context: LeafContext, value: Node?, leaf: Leaf) throws -> Bytes {
        guard var body = value?.bytes else {
            throw Abort.serverError
        }

        try body.append(contentsOf: stem.render(leaf, with: context))
        body.append(contentsOf: "</div>".makeBytes())
        return body
    }
}

public final class BoxClose: BasicTag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "box:close"

    public func run(arguments: ArgumentList) throws -> Node? {
        return .bytes("</div>".makeBytes())
    }
}
