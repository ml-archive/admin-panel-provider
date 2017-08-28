import Leaf
import Vapor

public final class Label: BasicTag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "label"

    public func run(arguments: ArgumentList) throws -> Node? {
        guard let text = arguments[0]?.string else {
            throw Error.invalidSyntax("label parse error: expected #label(text, <type>)")
        }
        let type = arguments[1]?.string ?? "default"
        let label = "<span class=\"label label-\(type)\">\(text)</span>"
        return .bytes(label.makeBytes())
    }
}

