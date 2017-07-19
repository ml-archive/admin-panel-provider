@testable import Leaf

final class TestableLoop: Tag {
    enum Error: Swift.Error {
        case expectedTwoArguments(have: [Argument])
        case expectedVariable(have: Argument)
        case expectedConstant(have: Argument)
    }

    struct Context {
        var args: [Argument]
        var didReturn: Bool
    }

    let name = "loop"

    func run(
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

    func render(
        stem: Stem,
        context: LeafContext,
        value: Node?,
        leaf: Leaf
    ) throws -> Bytes {
        guard let array = value?.array else { fatalError("run function MUST return an array") }
        func renderItem(_ item: Node) throws -> Bytes {
            context.push(item)
            let rendered = try stem.render(leaf, with: context)
            context.pop()
            return rendered
        }
        return try array.map(renderItem)
            .joined(separator: [.newLine])
            .flatMap { $0 }
    }
}
