import FluentProvider

public final class Action: Model {
    public let storage = Storage()

    public var name: String
    public let userId: Int
    public let message: String

    public init(
        name: String,
        userId: Int,
        message: String
    ) {
        self.name = name
        self.userId = userId
        self.message = message
    }

    public init(row: Row) throws {
        name = try row.get("name")
        userId = try row.get("userId")
        message = try row.get("message")
    }

    public func makeRow() throws -> Row {
        var row = Row()

        try row.set("name", name)
        try row.set("userId", userId)
        try row.set("message", message)

        return row
    }
}

extension Action: Timestampable {}

extension Action: JSONRepresentable {
    public func makeJSON() throws -> JSON {
        var json = JSON()

        try json.set("name", name)
        try json.set("userId", userId)
        try json.set("message", message)
        try json.set(Action.createdAtKey, createdAt)
        try json.set(Action.updatedAtKey, updatedAt)

        return json
    }
}

extension Action: Preparation {
    public static func prepare(_ database: Database) throws {
        try database.create(self) {
            $0.id()
            $0.string("name")
            $0.int("userId")
            $0.string("message")
        }
    }

    public static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Action {
    public static func report(_ user: AdminPanelUser, _ message: String) {
        do {
            let action = Action(name: user.name, userId: user.id?.int ?? 0, message: message)
            try action.save()
        } catch {
            // FIXME: report to bugsnag
            print(error)
        }
    }
}
