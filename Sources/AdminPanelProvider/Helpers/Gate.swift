import HTTP
import Vapor

public class Gate {
    public enum Role: Int {
        case superAdmin
        case admin
        case user

        public init?(from: String) {
            let from = from.lowercased()
            switch from {
            case "super admin": self = .superAdmin
            case "admin": self = .admin
            case "user": self = .user
            default: return nil
            }
        }
    }

    public static func allow(_ role: Role, requiredRole: Role) -> Bool {
        return role.rawValue <= requiredRole.rawValue
    }

    public static func allow(_ role: String, requiredRole: String) -> Bool {
        guard let role = Role.init(from: role), let requiredRole = Role.init(from: requiredRole) else {
            return false
        }

        return allow(role, requiredRole: requiredRole)
    }

    public static func allow(_ user: BackendUser, requiredRole: Role) -> Bool {
        guard let role = Role.init(from: user.role) else { return false }
        return allow(role, requiredRole: requiredRole)
    }

    public static func assertAllowed(_ user: BackendUser, requiredRole: Role) throws {
        guard allow(user, requiredRole: requiredRole) else {
            // Don't show them this endpoint exists
            throw Abort.notFound
        }
    }
}
