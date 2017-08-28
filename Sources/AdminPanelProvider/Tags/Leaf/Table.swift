import Leaf
import Vapor

public final class Table: BasicTag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "table"

    public func run(arguments: ArgumentList) throws -> Node? {
        var table = "<table class=\"table\"><tbody><tr>"

        for arg in arguments.list {
            guard let arg = arg.value(with: arguments.stem, in: arguments.context)?.string else {
                continue
            }

            table.append("<th>\(arg)</th>")
        }

        table.append("</tr>")

        return .bytes(table.makeBytes())
    }

    public func render(stem: Stem, context: LeafContext, value: Node?, leaf: Leaf) throws -> Bytes {
        guard var body = value?.bytes else {
            throw Abort.serverError
        }

        try body.append(contentsOf: stem.render(leaf, with: context))
        body.append(contentsOf: "</tbody></table>".makeBytes())
        return body
    }
}

public final class TableRows: Tag {
    public enum Error: Swift.Error {
        case expectedTwoArguments(have: [Argument])
        case expectedVariable(have: Argument)
        case expectedConstant(have: Argument)
    }

    public let name = "table:rows"

    public func run(
        tagTemplate: TagTemplate,
        arguments: ArgumentList
    ) throws -> Node? {
        guard arguments.count == 2 else { throw Error.expectedTwoArguments(have: arguments.list) }
        let variable = arguments.list[0]
        guard case let .variable(path: _, value: value) = variable else {
            throw Error.expectedVariable(have: variable)
        }
        let constant = arguments.list[1]
        guard case let .constant(value: leaf) = constant else {
            throw Error.expectedConstant(have: constant)
        }
        let innername = try arguments.stem
            .render(leaf, with: arguments.context)
            .makeString()

        guard let unwrapped = value else { return nil }
        let array = unwrapped.array ?? [unwrapped]
        let nodes = try array.enumerated().map { idx, val in
            return try Node(
                node: [
                    innername: val,
                    "index": idx,
                    "offset": idx + 1
                ]
            )
        }
        return .array(nodes)
    }

    public func render(
        stem: Stem,
        context: LeafContext,
        value: Node?,
        leaf: Leaf
    ) throws -> Bytes {
        guard let array = value?.array else { fatalError("run function MUST return an array") }
        func renderItem(_ item: Node) throws -> Bytes {
            var rendered = "<tr>".makeBytes()
            context.push(item)
            rendered.append(contentsOf: try stem.render(leaf, with: context))
            context.pop()
            rendered.append(contentsOf: "</tr>".makeBytes())
            return rendered
        }
        return try array.map(renderItem)
            .joined(separator: [.newLine])
            .flatMap { $0 }
    }
}
