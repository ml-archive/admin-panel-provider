import Leaf
import Vapor

public final class DateGroup: BasicTag {
    public init(){}
    public let name = "form:dategroup"

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

        let dateformat = arguments[2]?.string ?? "dd/mm/yyyy"
        let startDate = arguments[3]?.string ?? ""

        var template: [String] = [
            "<div class=\"form-group action-wrapper\(hasErrors ? " has-error" : "")\">",
            "<div class=\"input-group date\" data-provide=\"datepicker\" data-date-format=\"\(dateformat)\" data-date-start-date=\"\(startDate)\">",
            "<input type=\"text\" class=\"form-control\" id='\(fieldsetPath)' name=\"\(fieldsetPath)\" value=\"\(inputValue)\">",
            "<div class=\"input-group-addon\">",
            "<span class=\"glyphicon glyphicon-th\"></span>",
            "</div></div></div>"
        ]

        if let label = label {
            template.insert("<label class=\"control-label\" for=\"\(fieldsetPath)\">\(label)</label>", at: 1)
        }
        
        return .bytes(template.joined(separator: "\n").bytes)
    }
}

