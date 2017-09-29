import Leaf
import Vapor

public final class TimeSince: BasicTag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "timeSince"

    public func run(arguments: ArgumentList) throws -> Node? {
        guard let date = arguments[0]?.date else {
            return 0
        }

        let timeSince = date.timeUntilNow(fallbackAfter: arguments[1]?.int, fallbackFormat: arguments[2]?.string)
        return .bytes(timeSince.makeBytes())
    }
}
