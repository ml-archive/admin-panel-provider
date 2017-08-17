import Leaf

public final class IfNotEmpty: Tag {
    public enum Error: Swift.Error {
        case expectedSingleArgument(have: [Argument])
    }

    public let name = "ifNotEmpty"

    public func run(
        tagTemplate: TagTemplate,
        arguments: ArgumentList
    ) throws -> Node? {
        guard arguments.count == 1 else { throw Error.expectedSingleArgument(have: arguments.list) }
        return nil
    }

    public func shouldRender(
        tagTemplate: TagTemplate,
        arguments: ArgumentList,
        value: Node?
    ) -> Bool {
        guard let value = arguments[0] else { return false }
        // Existence of bool, evaluate bool.
        if let bool = value.bool { return bool }
        // Empty string value returns false.
        if value.string == "" { return false }
        if value.array?.isEmpty ?? true { return false }
        // Otherwise, not-nil returns true.
        return true
    }
}
