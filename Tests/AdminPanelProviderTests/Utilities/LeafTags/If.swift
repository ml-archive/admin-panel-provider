import Leaf

final class TestableIf: Tag {
    struct Context {
        var args: [Argument]
        var didReturn: Bool
    }

    enum Error: Swift.Error {
        case expectedSingleArgument(have: [Argument])
    }

    let name = "if"
    let renderer: LeafTestRenderer

    init(renderer: LeafTestRenderer) {
        self.renderer = renderer
    }

    func run(
        tagTemplate: TagTemplate,
        arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 1 else { throw Error.expectedSingleArgument(have: arguments.list) }
        return nil
    }

    func shouldRender(
        tagTemplate: TagTemplate,
        arguments: ArgumentList,
        value: Node?
    ) -> Bool {
        let didReturn: Bool
        if arguments[0] == nil {
            didReturn = false
        } else if let bool = value?.bool {
            didReturn = bool
        } else if arguments[0] == "" {
            didReturn = false
        } else {
            didReturn = true
        }

        let context = Context(args: arguments.list, didReturn: didReturn)
        renderer.context.ifStatements.append(context)

        return didReturn
    }
}
