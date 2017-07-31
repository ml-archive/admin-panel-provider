import Leaf
import Vapor

public final class CheckboxGroup: BasicTag {
    public init(){}
    public let name = "form:checkboxgroup"

    public func run(arguments: ArgumentList) throws -> Node? {
        guard
            arguments.count >= 2,
            case .variable(let fieldsetPathNodes, value: let fieldset) = arguments.list[0],
            let fieldsetPath = fieldsetPathNodes.last
            else {
                throw Abort(.internalServerError, reason: "FormTextGroup parse error, expecting: #form:textgroup(\"name\", \"default\", fieldset)")
        }

        // Retrieve input value, value from fieldset else passed default value
        let inputValue = fieldset?["value"]?.bool ?? arguments[1]?.bool ?? false

        let label = fieldset?["label"]?.string ?? fieldsetPath

        // This is not a required property
        let errors = fieldset?["errors"]?.array
        let hasErrors = !(errors?.isEmpty ?? true)

        // Start constructing the template
        var template = [String]()

        var classes = ""
        if let customClasses = arguments[2]?.string {
            classes.append(customClasses)
        }

        template.append("<div class='form-group \(hasErrors ? "has-error" : "")'>")
        template.append("<div class=\"checkbox\"><label><input class='\(classes)' type='checkbox' id='\(fieldsetPath)' name='\(fieldsetPath)' value='\(fieldsetPath)' \(inputValue ? "checked" : "")>\(label)</label></div>")

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
