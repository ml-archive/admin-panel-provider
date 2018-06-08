import Leaf
import Vapor

public final class DateGroup: BasicTag {
    public init() {}
    public let name = "form:dategroup"

    public func run(arguments: ArgumentList) throws -> Node? {
        guard
            arguments.count >= 2,
            case .variable(let fieldsetPathNodes, value: let fieldset) = arguments.list[0],
            let fieldsetPath = fieldsetPathNodes.last
        else {
            throw Abort(.internalServerError, reason: "DateGroup parse error, expecting: #form:dategroup(\"fieldset.name\", \"default\", \"dateFormat\", \"startDate\", \"attributes\")")
        }

        // Retrieve input value, value from fieldset else passed default value
        let inputValue = fieldset?["value"]?.string ?? arguments[1]?.string ?? ""
        let label = fieldset?["label"]?.string

        let errors = fieldset?["errors"]?.array
        let hasErrors = !(errors?.isEmpty ?? true)

        let dateformat = arguments[2]?.string ?? "dd/mm/yyyy"
        let startDate = arguments[3]?.string ?? ""

        let attributesHTML: String
        if let attributesNode = arguments[4] {
            let attributes: [String]
            if let attrArray = attributesNode.array {
                attributes = attrArray.flatMap {
                    $0.string
                }
            } else if let attrStr = attributesNode.string {
                attributes = attrStr.components(separatedBy: ",")
            } else {
                throw Abort(.internalServerError, reason: "DateGroup parse error, expecting: an array or comma separated list of custom attributes")
            }

            attributesHTML = attributes.joined(separator: ", ")
        } else {
            attributesHTML = ""
        }

        var template: [String] = [
            "<div class=\"form-group action-wrapper\(hasErrors ? " has-error" : "")\">",
            "<div class=\"input-group date\" data-provide=\"datepicker\" data-date-format=\"\(dateformat)\" data-date-start-date=\"\(startDate)\">",
            "<input type=\"text\" class=\"form-control\" id='\(fieldsetPath)' name=\"\(fieldsetPath)\" value=\"\(inputValue)\" \(attributesHTML)>",
            "<div class=\"input-group-addon\">",
            "<span class=\"glyphicon glyphicon-th\"></span>",
            "</div></div>"
        ]

        // If Fieldset has errors then loop through them and add help-blocks
        if let errors = errors {
            for e in errors {
                guard let errorString = e.string else {
                    continue
                }

                template.append("<span class='help-block'>\(errorString)</span>")
            }
        }

        template.append("</div>")

        if let label = label {
            template.insert("<label class=\"control-label\" for=\"\(fieldsetPath)\">\(label)</label>", at: 1)
        }
        
        return .bytes(template.joined(separator: "\n").bytes)
    }
}

