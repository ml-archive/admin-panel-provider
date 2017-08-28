import Leaf
import Vapor

public final class ImageRound: BasicTag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "image:round"

    public func run(arguments: ArgumentList) throws -> Node? {
        let path = arguments[0]?.string ?? ""
        let classes = arguments[1]?.string
        let attributes = arguments[2]?.string ?? ""

        let image = "<img src=\"\(path)\" class=\"img-circle \(classes != nil ? classes! : "")\" \(attributes)></img>"

        return .bytes(image.makeBytes())
    }
}
