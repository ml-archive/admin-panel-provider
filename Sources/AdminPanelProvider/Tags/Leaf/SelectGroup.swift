import Leaf
import Vapor

public final class SelectGroup: BasicTag {
    public init(){}
    public let name = "form:selectgroup"

    public func run(arguments: ArgumentList) throws -> Node? {
        guard
            arguments.count >= 3,
            let fields = arguments[0]?.array,
            case .variable(let fieldsetPathNodes, value: let fieldset) = arguments.list[1],
            let fieldsetPath = fieldsetPathNodes.last
            else {
                throw Abort(.internalServerError, reason: "FormSelectGroup parse error, expecting: #form:selectgroup(\"name\", \"default\", fieldset)")
        }

        // Retrieve input value(s), value(s) from fieldset else passed default value(s)
        let selected: [String]

        if let value = fieldset?["value"]?.string, !value.isEmpty {
            selected = [value]
        } else if let value = arguments[2]?.string, !value.isEmpty {
            selected = [value]
        } else if let value = fieldset?["value"]?.array {
            selected = value.flatMap { $0.string }
        } else if let value = arguments[2]?.array {
            selected = value.flatMap { $0.string }
        } else {
            selected = []
        }

        let label = fieldset?["label"]?.string ?? fieldsetPath

        // This is not a required property
        let errors = fieldset?["errors"]?.array
        let hasErrors = !(errors?.isEmpty ?? true)

        // Start constructing the template
        var template = [String]()

        var classes = "form-control "
        if let customClasses = arguments[2]?.string {
            classes.append(customClasses)
        }

        template.append("<div class='form-group \(hasErrors ? "has-error" : "")'>")
        template.append("<label class='control-label' for='\(fieldsetPath)'>\(label)</label>")
        template.append("<select class='\(classes)' id='\(fieldsetPath)' name='\(fieldsetPath)'")

        if let attributesNode = arguments[3] {
            let attributes: [String]
            if let attrArray = attributesNode.array {
                attributes = attrArray.flatMap {
                    $0.string
                }
            } else if let attrStr = attributesNode.string {
                attributes = attrStr.components(separatedBy: ",")
            } else {
                throw Abort(.internalServerError, reason: "FormSelectGroup parse error, expecting: an array or comma separated list of custom attributes")
            }

            template.append(contentsOf: attributes)
        }

        template.append("/>")

        for field in fields {
            if let field = field.string {
                template.append("<option value=\"\(field)\"\(selected.contains(field) ? " selected" : "")>\(field)</option>")
            }
        }

        template.append("</select>")

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

        // Return template
        return .bytes(template.joined().bytes)
    }
}
