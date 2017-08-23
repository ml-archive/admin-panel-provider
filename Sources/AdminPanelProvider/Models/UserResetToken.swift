import Vapor
import FluentProvider

public final class UserResetToken: Model {
    public let storage = Storage()
    public static let name = "adminPanelUserResetToken"
    
    public let email: String
    public let token: String
    public var expireAt: Date
    public var usedAt: Date?

    public init(email: String, token: String, expireAt: Date) {
        self.email = email
        self.token = token
        self.expireAt = expireAt
    }

    public init(row: Row) throws {
        email = try row.get("email")
        token = try row.get("token")
        expireAt = try row.get("expireAt")
        usedAt = row["usedAt"]?.date
    }

    public func makeRow() throws -> Row {
        var row = Row()

        try row.set("email", email)
        try row.set("token", token)
        try row.set("expireAt", expireAt)
        try row.set("usedAt", usedAt)

        return row
    }
}

extension UserResetToken {
    public var canBeUsed: Bool {
        guard usedAt == nil && expireAt > Date() else {
            return false
        }

        return true
    }

    public func use() throws {
        usedAt = Date()
        try save()
    }
}

extension UserResetToken: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create(self) {
            $0.id()
            $0.string("email", unique: true)
            $0.string("token")
            $0.date("expireAt")
            $0.date("usedAt", optional: true)
        }

        try database.index("email", for: self)
        try database.index("token", for: self)
    }

    public static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
