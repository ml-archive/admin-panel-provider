import Leaf
import Vapor

public final class GateAllow: BasicTag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "gate:allow"

    public func run(arguments: ArgumentList) throws -> Node? {
        guard arguments.count == 2 else {
            throw Error.invalidSyntax("gate:allow parse error: expected #gate:allow(userRole, requiredRole)")
        }
        return nil
    }

    public func shouldRender(tagTemplate: TagTemplate, arguments: ArgumentList, value: Node?) -> Bool {
        guard let userRole = arguments[0]?.string, let requiredRole = arguments[1]?.string else {
            return false
        }

        return Gate.allow(userRole, requiredRole: requiredRole)
    }
}
