import Leaf
import Vapor

public final class ButtonDelete: BasicTag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "button:delete"

    public func run(arguments: ArgumentList) throws -> Node? {
        guard let path = arguments[0]?.string else {
            throw Error.invalidSyntax("button:delete parse error: expected button:delete(path, <title>, <message>")
        }

        let title = arguments[1]?.string ?? ""
        let message = arguments[2]?.string ?? ""

        let button = "<a href=\"\(path)\" class=\"btn btn-box-tool\" data-toggle=\"tooltip\" data-delete=\"true\" data-title=\"Delete\" data-header=\"\(title)\" data-text=\"\(message)\"><span class=\"fa fa-times\"></span><span class=\"sr-only\">Delete user</span></a>"

        return .bytes(button.makeBytes())
    }
}
