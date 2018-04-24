import HTTP
import Vapor

/// Gates content according to a user's role
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

    /// Returns whether or not a given role has more than or equal permissions than required
    public static func allow(_ role: Role, requiredRole: Role) -> Bool {
        return role.rawValue <= requiredRole.rawValue
    }

    /// Returns whether or not a given role has more than or equal permissions than required
    public static func allow(_ role: String, requiredRole: String) -> Bool {
        guard let role = Role.init(from: role), let requiredRole = Role.init(from: requiredRole) else {
            return false
        }

        return allow(role, requiredRole: requiredRole)
    }

    /// Returns whether or not a given user has more than or equal permissions than required
    public static func allow<U: AdminPanelUserType>(_ user: U, requiredRole: Role) -> Bool {
        guard let role = Role.init(from: user.role) else { return false }
        return allow(role, requiredRole: requiredRole)
    }

    /// Throws if a user doesn't have equal or more permissions than required
    public static func assertAllowed<U: AdminPanelUserType>(_ user: U, requiredRole: Role) throws {
        guard allow(user, requiredRole: requiredRole) else {
            // Don't show them this endpoint exists
            throw Abort.notFound
        }
    }
}
