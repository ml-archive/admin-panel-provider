import Leaf
import Vapor
import Foundation

public final class MenuToggle: Tag {
    public init(){}
    public let name = "menu:toggle"

    public func run(tagTemplate: TagTemplate, arguments: ArgumentList) throws -> Node? {
        guard
            let icon = arguments[0]?.string,
            let header = arguments[1]?.string
        else {
            throw Abort(.internalServerError, reason: "menu:toggle parse error: expected `menu:toggle(icon, header, <label>, <label class>`")
        }

        let label = arguments[2]?.string

        var template: [String] = [
            "<li class=\"dropdown messages-menu\">",
            "<a href=\"#\" class=\"dropdown-toggle\" data-toggle=\"dropdown\">",
            "<i class=\"fa fa-\(icon)\"></i>",
            "</a>",
            "<ul class=\"dropdown-menu\">",
            "<li class=\"header\">\(header)</li>",
        ]

        if let label = label {
            let labelClass = arguments[3]?.string ?? "default"
            template.insert("<span class=\"label label-\(labelClass)\">\(label)</span>", at: 2)
        }

        return .bytes(template.joined(separator: "\n").makeBytes())
    }

    public func render(stem: Stem, context: LeafContext, value: Node?, leaf: Leaf) throws -> Bytes {
        guard var body = value?.bytes else {
            throw Abort.serverError
        }

        try body.append(contentsOf: stem.render(leaf, with: context))
        body.append(contentsOf: "</ul></li>".makeBytes())
        return body
    }
}


