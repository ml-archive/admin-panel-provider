import Leaf
import Vapor

public final class ColorGroup: BasicTag {
    public init(){}
    public let name = "form:colorgroup"

    public func run(arguments: ArgumentList) throws -> Node? {
        guard
            arguments.count >= 2,
            case .variable(let fieldsetPathNodes, value: let fieldset) = arguments.list[0],
            let fieldsetPath = fieldsetPathNodes.last
            else {
                throw Abort(.internalServerError, reason: "FormDateGroup parse error, expecting: #form:dategroup(\"name\", \"default\", fieldset)")
        }

        // Retrieve input value, value from fieldset else passed default value
        let inputValue = fieldset?["value"]?.string ?? arguments[1]?.string ?? ""
        let label = fieldset?["label"]?.string

        let errors = fieldset?["errors"]?.array
        let hasErrors = !(errors?.isEmpty ?? true)

        var template: [String] = [
            "<div class=\"form-group action-wrapper\(hasErrors ? " has-error" : "")\">",
            "<div id=\"\(fieldsetPath)-cp\" class=\"input-group colorpicker-component\">",
            "<input type=\"text\" class=\"form-control\" id='\(fieldsetPath)' name=\"\(fieldsetPath)\" value=\"\(inputValue)\">",
            "<span class=\"input-group-addon\"><i></i></span>",
            "</div></div><script>",
            "$(function() { $('#\(fieldsetPath)-cp').colorpicker(); });",
            "</script>"
        ]

        if let label = label {
            template.insert("<label class=\"control-label\" for=\"\(fieldsetPath)\">\(label)</label>", at: 1)
        }

        return .bytes(template.joined(separator: "\n").bytes)
    }
}
