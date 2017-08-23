import Vapor

public struct UserForm {
    public let name: String
    public let nameErrors: [String]
    public let email: String
    public let emailErrors: [String]
    public let title: String
    public let titleErrors: [String]
    public let role: String
    public let roleErrors: [String]
    public let password: String
    public let passwordErrors: [String]
    public let passwordRepeat: String
    public let passwordRepeatErrors: [String]

    public let hasRandomPassword: Bool
    public let shouldResetPassword: Bool
    public let sendEmail: Bool

    public init(
        name: String? = nil,
        nameErrors: [String] = [],
        email: String? = nil,
        emailErrors: [String] = [],
        title: String? = nil,
        titleErrors: [String] = [],
        role: String? = nil,
        roleErrors: [String] = [],
        password: String? = nil,
        passwordErrors: [String] = [],
        passwordRepeat: String? = nil,
        passwordRepeatErrors: [String] = [],
        hasRandomPassword: Bool? = nil,
        shouldResetPassword: Bool? = nil,
        sendEmail: Bool? = nil
    ) {
        self.name = name ?? ""
        self.nameErrors = nameErrors
        self.email = email ?? ""
        self.emailErrors = emailErrors
        self.title = title ?? ""
        self.titleErrors = titleErrors
        self.role = role ?? ""
        self.roleErrors = roleErrors
        self.password = password ?? ""
        self.passwordErrors = passwordErrors
        self.passwordRepeat = passwordRepeat ?? ""
        self.passwordRepeatErrors = passwordRepeatErrors
        self.hasRandomPassword = hasRandomPassword ?? false
        self.shouldResetPassword = shouldResetPassword ?? false
        self.sendEmail = sendEmail ?? false
    }
}

extension UserForm {
    public static func validating(_ data: Content, ignoreRole: Bool = false) -> (UserForm, Bool) {
        let name = data["name"]?.string
        let email = data["email"]?.string
        let title = data["title"]?.string
        let role = data["role"]?.string
        let shouldResetPassword = data["shouldResetPassword"]?.string != nil
        let sendEmail = data["sendEmail"]?.string != nil
        let password = data["password"]?.string
        let passwordRepeat = data["passwordRepeat"]?.string

        return validate(
            name: name,
            email: email,
            title: title,
            role: role,
            shouldResetPassword: shouldResetPassword,
            sendEmail: sendEmail,
            password: password,
            passwordRepeat: passwordRepeat,
            ignoreRole: ignoreRole
        )
    }

    public static func validate(
        name: String?,
        email: String?,
        title: String?,
        role: String?,
        shouldResetPassword: Bool?,
        sendEmail: Bool?,
        password: String?,
        passwordRepeat: String?,
        ignoreRole: Bool
    ) -> (UserForm, Bool) {
        var shouldResetPassword = shouldResetPassword
        var password = password
        var hasErrors = false

        var nameErrors: [String] = []
        var emailErrors: [String] = []
        var titleErrors: [String] = []
        var passwordErrors: [String] = []
        var passwordRepeatErrors: [String] = []
        var roleErrors: [String] = []

        let requiredFieldError = "Field is required"
        if name == nil {
            nameErrors.append(requiredFieldError)
            hasErrors = true
        }

        if email == nil {
            emailErrors.append(requiredFieldError)
            hasErrors = true
        }

        if title == nil {
            titleErrors.append(requiredFieldError)
            hasErrors = true
        }

        if role == nil && !ignoreRole {
            roleErrors.append(requiredFieldError)
            hasErrors = true
        }

        let nameCharactercount = name?.utf8.count ?? 0
        if nameCharactercount < 1 || nameCharactercount > 191 {
            nameErrors.append("Must be between 1 and 191 characters long")
            hasErrors = true
        }

        let emailCharactercount = email?.utf8.count ?? 0
        if emailCharactercount < 1 || emailCharactercount > 191 {
            emailErrors.append("Must be between 1 and 191 characters long")
            hasErrors = true
        }

        if password != passwordRepeat {
            passwordRepeatErrors.append("Passwords do not match")
            hasErrors = true
        }

        let hasRandomPassword = (password?.isEmpty ?? true) && (passwordRepeat?.isEmpty ?? true)
        if hasRandomPassword {
            password = String.random(12)
            shouldResetPassword = true
        } else {
            if let password = password {
                let passwordCharactercount = password.utf8.count
                if passwordCharactercount < 8 || passwordCharactercount > 191 {
                    passwordErrors.append("Must be between 8 and 191 characters long")
                    hasErrors = true
                }
            } else {
                passwordErrors.append(requiredFieldError)
                hasErrors = true
            }

            if let passwordRepeat = passwordRepeat {
                let passwordRepeatCharacterCount = passwordRepeat.utf8.count
                if passwordRepeatCharacterCount < 8 || passwordRepeatCharacterCount > 191 {
                    passwordRepeatErrors.append("Must be between 8 and 191 characters long")
                    hasErrors = true
                }
            } else {
                passwordRepeatErrors.append(requiredFieldError)
                hasErrors = true
            }
        }

        return (
            UserForm(
                name: name,
                nameErrors: nameErrors,
                email: email,
                emailErrors: emailErrors,
                title: title,
                titleErrors: titleErrors,
                role: role,
                roleErrors: roleErrors,
                password: password,
                passwordErrors: passwordErrors,
                passwordRepeat: passwordRepeat,
                passwordRepeatErrors: passwordRepeatErrors,
                hasRandomPassword: hasRandomPassword,
                shouldResetPassword: shouldResetPassword,
                sendEmail: sendEmail
            ),
            hasErrors
        )
    }
}

extension UserForm: NodeRepresentable {
    public func makeNode(in context: Context?) throws -> Node {
        let nameObj = try Node(node: [
            "label": "Name",
            "value": .string(name),
            "errors": Node(node: nameErrors)
        ])

        let emailObj = try Node(node: [
            "label": "Email",
            "value": .string(email),
            "errors": Node(node: emailErrors)
        ])

        let titleObj = try Node(node: [
            "label": "Title",
            "value": .string(title),
            "errors": Node(node: titleErrors)
        ])

        let roleObj = try Node(node: [
            "label": "Role",
            "value": .string(role),
            "errors": Node(node: roleErrors)
        ])

        let shouldResetPasswordObj = Node(node: [
            "label": "Should reset password",
            "value": .bool(shouldResetPassword)
        ])

        let sendEmailObj = Node(node: [
            "label": "Send email with information",
            "value": .bool(sendEmail)
        ])

        let passwordObj = try Node(node: [
            "label": "Password",
            "errors": Node(node: passwordErrors)
        ])

        let passwordRepeatObj = try Node(node: [
            "label": "Repeat password",
            "errors": Node(node: passwordRepeatErrors)
        ])

        var node = Node.object([:])
        try node.set("name", nameObj)
        try node.set("email", emailObj)
        try node.set("title", titleObj)
        try node.set("role", roleObj)
        try node.set("shouldResetPassword", shouldResetPasswordObj)
        try node.set("sendEmail", sendEmailObj)
        try node.set("password", passwordObj)
        try node.set("passwordRepeat", passwordRepeatObj)

        return node
    }
}
