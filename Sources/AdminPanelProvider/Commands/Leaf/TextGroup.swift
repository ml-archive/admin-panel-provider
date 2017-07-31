import Leaf
import Vapor

/// #form:textgroup(**key**, **value**, **fieldset**, classes *(optional)*, attributes *(optional)*)
///
/// Arguments:
///
/// [0] = The name of the input (the key that gets posted) (1)
///
/// [1] = The value of the input (the value that gets posted) (defaults to empty string) (2)
///
/// [2] = The VaporForms Fieldset of the entire model (1, 2)
///
/// **1** - All the arguments are actually required. We need to throw exceptions at people if they don't supply all of them
///
/// **2** - It would be awesome if you could only post the exact Field of the Fieldset so we don't need to find it in this code (its gonna get repetetive)
///
/// The <label> will get its value from the Fieldset
///
/// If the Fieldset has the "errors" property the form-group will get the has-error css class and all errors will be added as help-block's to the form-group
///
/// given input:
///
/// ```
/// let fieldset = Node([
///     "name": StringField(
///     label: "Name"
/// ])
///
/// #form:textgroup("name", "John Doe", fieldset)
/// ```
///
/// expected output if fieldset is valid:
///
/// ```
/// <div class="form-group">
/// <label class="control-label" for="name">Name</label>
/// <input class="form-control" type="text" id="name" name="name" value="John Doe" />
/// </div>
/// ```
///
/// expected output for `#form:textgroup("name", "John Doe", fieldset, "center-text dark", "a='hello',b='world'")`:
///
/// ```
/// <div class="form-group">
/// <label class="control-label" for="name">Name</label>
/// <input class="form-control center-text dark" type="text" id="name" name="name" value="John Doe" a='hello' b='world'/>
/// </div>
/// ```
///
/// expected output if fieldset is invalid:
///
/// ```
/// <div class="form-group has-error">
/// <label class="control-label" for="name">Name</label>
/// <input class="form-control" type="text" id="name" name="name" value="John Doe" />
/// <span class="help-block">...validation message</span>
/// </div>
/// ```

public func this(_ lhs: String?, or rhs: String?) -> String {
    if let lhs = lhs, !lhs.isEmpty {
        return lhs
    }

    if let rhs = rhs, !rhs.isEmpty {
        return rhs
    }

    return ""
}

public final class TextGroup: BasicTag {
    public init(){}
    public let name = "form:textgroup"

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
        template.append("<input class='\(classes)' type='text' id='\(fieldsetPath)' name='\(fieldsetPath)' value='\(inputValue)' ")

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
