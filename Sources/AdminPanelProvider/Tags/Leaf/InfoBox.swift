import Leaf
import Vapor

public final class InfoBox: BasicTag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "infobox"

    public func run(arguments: ArgumentList) throws -> Node? {
        guard
            arguments.count >= 2,
            let title = arguments[0]?.string,
            let number = arguments[1]?.string
        else {
            throw Error.invalidSyntax("Expected `infobox(title, number, <colour>, <icon>)`")
        }

        let colour = arguments[2]?.string ?? "blue"
        let icon = arguments[3]?.string ?? "star"

        var infobox = [
            "<div class=\"info-box\">"
        ]

        infobox.append("<span class=\"info-box-icon bg-\(colour)\"><i class=\"\(icon)\"></i></span>")
        infobox.append("<div class=\"info-box-content\">")
        infobox.append("<span class=\"info-box-text\">\(title)</span>")
        infobox.append("<span class=\"info-box-number\">\(number)</span>")
        infobox.append("</div>\n</div>")

        return .bytes(infobox.joined(separator: "\n").makeBytes())
    }
}
