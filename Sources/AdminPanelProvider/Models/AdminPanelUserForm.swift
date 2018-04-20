import Forms
import Validation
import Vapor

// sourcery: form
public struct AdminPanelUserForm: AdminPanelUserFormType {
    public let nameField: FormField<String>
    public let emailField: FormField<String>
    public let passwordField: FormField<String>
    public let titleField: FormField<String>
    public let roleField: FormField<String>
    public let shouldResetPasswordField: FormField<Bool>

    init(
        userId: Identifier? = nil,
        name: String? = nil,
        email: String? = nil,
        password: String? = nil,
        title: String? = nil,
        role: String? = nil,
        avatar: String? = nil,
        shouldResetPassword: Bool = false
    ) {
        let stringLengthValidator = Count<String>.containedIn(low: 1, high: 191)

        let emailValidator = EmailValidator() && UniqueEntityValidator(
            fieldName: "email",
            exceptId: userId,
            countOfEntities: AdminPanelUser.countOfEntities,
            errorOnExist: ValidatorError.failure(
                type: "User email",
                reason: "Provided email already exists."
            )
        )

        nameField = FormField(
            key: "name",
            label: "Name",
            value: name,
            validator: stringLengthValidator.allowingNil(false)
        )
        emailField = FormField(
            key: "email",
            label: "Email",
            value: email,
            validator: emailValidator.allowingNil(false)
        )
        // TODO: add more password restrictions
        let passwordValidator = Count<String>.containedIn(low: 6, high: 191)
        passwordField = FormField(
            key: "password",
            label: "Password",
            value: password,
            validator: passwordValidator.allowingNil(true)
        )
        titleField = FormField(
            key: "title",
            label: "Title",
            value: title,
            validator: stringLengthValidator.allowingNil(false)
        )
        roleField = FormField(
            key: "role",
            label: "Role",
            value: role,
            validator: stringLengthValidator.allowingNil(false)
        )
        shouldResetPasswordField = FormField(
            key: "shouldResetPassword",
            label: "Should Reset Password",
            value: shouldResetPassword
        )
    }
}

extension AdminPanelUserForm {
    public var fields: [FieldType] {
        return [
            nameField,
            emailField,
            passwordField,
            titleField,
            roleField,
            shouldResetPasswordField
        ]
    }
}

extension AdminPanelUserForm {
    public var name: String? {
        return nameField.value
    }
    public var email: String? {
        return emailField.value
    }
    public var password: String? {
        return passwordField.value
    }
    public var title: String? {
        return titleField.value
    }
    public var role: String? {
        return roleField.value
    }
    public var shouldResetPassword: Bool {
        return shouldResetPasswordField.value ?? false
    }
}

extension AdminPanelUserForm {
    public func assertValues(errorOnNil: Error = Abort(.internalServerError)) throws -> (
        name: String,
        email: String,
        title: String,
        role: String
    ) {
        guard
            let name = name,
            let email = email,
            let title = title,
            let role = role
        else {
            throw errorOnNil
        }

        return (
            name: name,
            email: email,
            title: title,
            role: role
        )
    }
}

extension AdminPanelUserForm: RequestInitializable {
    public init(request: Request) throws {
        let content = request.data
        try self.init(
            name: content.get("name"),
            email: content.get("email"),
            password: content.get("password"),
            title: content.get("title"),
            role: content.get("role"),
            shouldResetPassword: content.get("shouldResetPassword")
        )
    }
}

extension AdminPanelUserForm {
    public init(user: AdminPanelUser) {
        self.init(
            name: user.name,
            email: user.email,
            title: user.title,
            role: user.role,
            shouldResetPassword: user.shouldResetPassword
        )
    }
}
