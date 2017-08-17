import Leaf
import Vapor

public final class FormOpen: BasicTag {
    public enum Error: Swift.Error {
        case invalidSyntax(String)
    }

    public init() {}
    public let name = "form:open"

    public func run(arguments: ArgumentList) throws -> Node? {
        let count = arguments.count
        guard
            count == 2 || count == 3,
            let path = arguments[0]?.string,
            let method = arguments[1]?.string
        else {
            throw Error.invalidSyntax("Invalid argument count. Expected `#form:open(path, method)` or `#form:open(path, method, isFileUpload`")
        }

        let isFileUpload = count == 3 ? arguments[2]?.bool ?? false : false

        let form: String
        if isFileUpload {
            form = "<form method='\(method)' action='\(path)' enctype='multipart/form-data'>"
        } else {
            form = "<form method='\(method)' action='\(path)'>"
        }

        return .bytes(form.makeBytes())
    }
}



/// Close a form
///
/// given input:
/// ```
///     #form:close()
/// ```
///
/// expected output:
/// ```
/// </form>
/// ```
public class FormClose: BasicTag {
    public init(){}
    public let name = "form:close"

    public func run(arguments: ArgumentList) throws -> Node? {
        return .bytes("</form>".bytes)
    }
}
