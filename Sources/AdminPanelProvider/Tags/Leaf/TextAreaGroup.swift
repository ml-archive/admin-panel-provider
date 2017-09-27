import Leaf
import Vapor

public final class TextAreaGroup: BasicTag {
    public init(){}
    public let name = "form:textareagroup"

    public func run(arguments: ArgumentList) throws -> Node? {
        guard
            arguments.count >= 2,
            case .variable(let fieldsetPathNodes, value: let fieldset) = arguments.list[0],
            let fieldsetPath = fieldsetPathNodes.last
            else {
                throw Abort(.internalServerError, reason: "FormTextGroup parse error, expecting: #form:textgroup(\"name\", \"default\", fieldset)")
        }

        // Retrieve input value, value from fieldset else passed default value
        let inputValue = this(fieldset?["value"]?.string, or: arguments[1]?.string)

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
        template.append("<textarea class='\(classes)' id='\(fieldsetPath)' name='\(fieldsetPath)'")

        if let attributesNode = arguments[3] {
            let attributes: [String]
            if let attrArray = attributesNode.array {
                attributes = attrArray.flatMap {
                    $0.string
                }
            } else if let attrStr = attributesNode.string {
                attributes = attrStr.components(separatedBy: ",")
            } else {
                throw Abort(.internalServerError, reason: "FormTextGroup parse error, expecting: an array or comma separated list of custom attributes")
            }

            template.append(contentsOf: attributes)
        }

        template.append("/>")
        template.append(inputValue)
        template.append("</textarea>")

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
