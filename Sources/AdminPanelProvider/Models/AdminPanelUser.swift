import AuditProvider
import AuthProvider
import BCrypt
import FluentProvider
import Forms
import Storage
import Vapor

public protocol AdminPanelUserFormType: Form {
    var role: String? { get }
    var password: String? { get }
}

public protocol AdminPanelUserType:
    AuditCustomDescribable,
    NodeRepresentable,
    Parameterizable,
    PasswordAuthenticatable,
    Preparation,
    SessionPersistable,
    SoftDeletable,
    ViewDataRepresentable
{
    static func makeSeededUser() throws -> Self
    static func makeSSOUser(withEmail: String) throws -> Self

    associatedtype Form: AdminPanelUserFormType, RequestInitializable

    /// Create a new user with the values from the form
    ///
    /// - Parameters:
    ///   - form: form with user values
    ///   - panelConfig: panel configuration
    ///   - req: the request
    init(form: Form, panelConfig: PanelConfig?, req: Request?) throws

    /// Should update any fields which have corresponding values in the form except password.
    ///
    /// - Parameters:
    ///   - form: form with updated values
    ///   - panelConfig: panel configuration
    ///   - req: the request
    func updateNonPasswordValues(form: Form, panelConfig: PanelConfig?, req: Request?) throws
    func makeForm() -> Form

    static func hashPassword(_: String) throws -> String

    var email: String { get set }
    var name: String { get set }
    var role: String { get set }

    var password: String { get set }
    var shouldResetPassword: Bool { get set }

    /// database key name for `role` property
    static var roleKey: String { get }

    /// database key name for `email` property
    static var emailKey: String { get }
}

extension AdminPanelUserType {
    public static var roleKey: String { return "role" }
    public static var emailKey: String { return "email" }

    public static func hashPassword(_ password: String) throws -> String {
        return try BCryptHasher().make(password.makeBytes()).makeString()
    }

    public static func authenticate(_ credentials: Password) throws -> Self {
        guard
            let user = try makeQuery().filter(emailKey, credentials.username).first(),
            try BCryptHasher().check(credentials.password, matchesHash: user.password)
        else {
            throw Abort.unauthorized
        }

        return user
    }
}

extension AdminPanelUser: AdminPanelUserType {
    public static func makeSeededUser() throws -> AdminPanelUser {
        return try .init(
            name: "Admin",
            title: "Default admin account",
            email: "admin@admin.com",
            password: "admin",
            role: "Super Admin",
            shouldResetPassword: false,
            avatar: nil
        )
    }

    public static func makeSSOUser(withEmail email: String) throws -> AdminPanelUser {
        return try .init(
            name: "Admin",
            title: "Nodes Admin",
            email: email,
            password: String.random(16),
            role: "Super Admin",
            shouldResetPassword: false,
            avatar: nil
        )
    }

    public convenience init(
        form: AdminPanelUserForm,
        panelConfig: PanelConfig?,
        req: Request?
    ) throws {
        let values = try form.assertValues()

        // extract avatar from request
        var avatar: String? = nil
        if
            let req = req,
            let panelConfig = panelConfig,
            let profileImage = req.data["profileImage"]?.string,
            profileImage.hasPrefix("data:"),
            panelConfig.isStorageEnabled
        {
            let path = try Storage.upload(dataURI: profileImage, folder: "profile")
            avatar = path
        }

        let newPassword: String
        let shouldResetPassword: Bool

        if let password = form.password, !password.isEmpty {
            newPassword = password
            shouldResetPassword = form.shouldResetPassword
        } else {
            newPassword = "" // this will be overwritten by the controller!
            shouldResetPassword = true
        }

        try self.init(
            name: values.name,
            title: values.title,
            email: values.email,
            password: AdminPanelUser.hashPassword(newPassword),
            role: values.role,
            shouldResetPassword: shouldResetPassword,
            avatar: avatar
        )
    }

    public func updateNonPasswordValues(
        form: AdminPanelUserForm,
        panelConfig: PanelConfig?,
        req: Request?
    ) throws {
        if let name = form.name {
            self.name = name
        }
        if let title = form.title {
            self.title = title
        }
        if let email = form.email {
            self.email = email
        }

        if
            let req = req,
            let panelConfig = panelConfig,
            let profileImage = req.data["profileImage"]?.string,
            profileImage.hasPrefix("data:"),
            panelConfig.isStorageEnabled
        {
            let path = try Storage.upload(dataURI: profileImage, folder: "profile")
            avatar = path
        }
    }

    public func makeForm() -> AdminPanelUserForm {
        return AdminPanelUserForm(user: self)
    }
}

public final class AdminPanelUser: Model {
    public let storage = Storage()

    public var avatar: String?
    public var email: String
    public var name: String
    public var password: String
    public var role: String
    public var shouldResetPassword: Bool
    public var title: String

    public init(
        name: String,
        title: String,
        email: String,
        password: String,
        role: String,
        shouldResetPassword: Bool,
        avatar: String?
    ) throws {
        self.name = name
        self.title = title
        self.email = email
        self.password = try BCryptHasher().make(password.makeBytes()).makeString()
        self.role = role
        self.shouldResetPassword = shouldResetPassword
        self.avatar = avatar
    }

    public init(row: Row) throws {
        name = try row.get("name")
        title = try row.get("title")
        email = try row.get(AdminPanelUser.emailKey)
        password = try row.get("password")
        role = try row.get(AdminPanelUser.roleKey)
        shouldResetPassword = try row.get(AdminPanelUser.shouldResetPasswordKey)
        avatar = row["avatar"]?.string
    }

    public func makeRow() throws -> Row {
        var row = Row()

        try row.set("name", name)
        try row.set("title", title)
        try row.set(AdminPanelUser.emailKey, email)
        try row.set("password", password)
        try row.set(AdminPanelUser.roleKey, role)
        try row.set(AdminPanelUser.shouldResetPasswordKey, shouldResetPassword)
        try row.set("avatar", avatar)

        return row
    }
}

extension AdminPanelUser: ViewDataRepresentable {
    public var avatarUrl: String {
        return avatar ?? "https://api.adorable.io/avatars/150/\(email).png"
    }

    public func makeViewData() throws -> ViewData {
        return try ViewData(viewData: [
            "id": .string(id?.string ?? "0"),
            "name": .string(name),
            "title": .string(title),
            AdminPanelUser.emailKey: .string(email),
            AdminPanelUser.roleKey: .string(role),
            "avatarUrl": .string(Storage.getCDNPath(optional: avatar) ?? avatarUrl)
        ])
    }
}

extension AdminPanelUser: NodeRepresentable {
    public func makeNode(in context: Context?) throws -> Node {
        return try Node([
            "id": .string(id?.string ?? "0"),
            "name": .string(name),
            "title": .string(title),
            "email": .string(email),
            AdminPanelUser.roleKey: .string(role),
            "avatarUrl": .string(Storage.getCDNPath(optional: avatar) ?? avatarUrl)
        ])
    }
}

extension AdminPanelUser: Author {}
extension AdminPanelUser: Timestampable {}
extension AdminPanelUser: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create(self) {
            $0.id()
            $0.string("name")
            $0.string("title")
            $0.string(AdminPanelUser.emailKey)
            $0.string("password")
            $0.string(AdminPanelUser.roleKey)
            $0.bool(AdminPanelUser.shouldResetPasswordKey)
            $0.string("avatar", optional: true)
        }
    }

    public static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension AdminPanelUser: AuditCustomDescribable {
    public static var auditDescription: String {
        return "User"
    }
}

// MARK: - Column Names in Database
extension AdminPanelUser {

    /// Should Reset Password Key
    static var shouldResetPasswordKey: String {
        switch keyNamingConvention {
        case .camelCase:
            return "shouldResetPassword"
        case .snake_case:
            return "should_reset_password"
        }
    }
}
