import Audit
import Vapor
import BCrypt
import Storage
import AuthProvider
import FluentProvider

public final class User: Model {
    public let storage = Storage()
    public static let name = "adminPanelUser"

    public var name: String
    public var title: String
    public var email: String
    public var password: String
    public var role: String
    public var shouldResetPassword: Bool
    public var avatar: String?

    public var avatarUrl: String {
        return avatar ?? "https://api.adorable.io/avatars/150/\(email).png"
    }

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
        email = try row.get("email")
        password = try row.get("password")
        role = try row.get("role")
        shouldResetPassword = try row.get("shouldResetPassword")
        avatar = row["avatar"]?.string
    }

    public func makeRow() throws -> Row {
        var row = Row()

        try row.set("name", name)
        try row.set("title", title)
        try row.set("email", email)
        try row.set("password", password)
        try row.set("role", role)
        try row.set("shouldResetPassword", shouldResetPassword)
        try row.set("avatar", avatar)

        return row
    }
}

extension User {
    public func updatePassword(_ newPass: String) throws {
        password = try BCryptHasher().make(newPass.makeBytes()).makeString()
        try save()
    }
}

extension User: ViewDataRepresentable {
    public func makeViewData() throws -> ViewData {
        return try ViewData(viewData: [
            "id": .number(.int(id?.int ?? 0)),
            "name": .string(name),
            "title": .string(title),
            "email": .string(email),
            "role": .string(role),
            "avatarUrl": .string(Storage.getCDNPath(optional: avatar) ?? avatarUrl)
        ])
    }
}

extension User: NodeRepresentable {
    public func makeNode(in context: Context?) throws -> Node {
        return try Node([
            "id": Node.number(.int(id?.int ?? 0)),
            "name": .string(name),
            "title": .string(title),
            "email": .string(email),
            "role": .string(role),
            "avatarUrl":  .string(Storage.getCDNPath(optional: avatar) ?? avatarUrl)
        ])
    }
}

extension User: Author {}
extension User: Timestampable {}
extension User: SoftDeletable {}
extension User: SessionPersistable {}
extension User: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create(self) {
            $0.id()
            $0.string("name")
            $0.string("title")
            $0.string("email")
            $0.string("password")
            $0.string("role")
            $0.bool("shouldResetPassword")
            $0.string("avatar", optional: true)
        }
    }

    public static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
extension User: PasswordAuthenticatable {
    public static func authenticate(_ credentials: Password) throws -> User {
        guard
            let user = try User.makeQuery().filter("email", credentials.username).first(),
            try BCryptHasher().check(credentials.password, matchesHash: user.password)
        else {
            throw Abort.unauthorized
        }

        return user
    }
}
extension User: AuditCustomDescribable {
    public static var auditDescription: String {
        return "User"
    }
}
