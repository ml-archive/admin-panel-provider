import Vapor
import Console

/// Seeds the admin panel with a default user
public final class Seeder: Command, ConfigInitializable {
    public let id = "admin-panel:seeder"

    public let help: [String] = [
        "Seeds the default user for the admin panel"
    ]

    public let console: ConsoleProtocol

    public init(config: Config) throws {
        self.console = try config.resolveConsole()
    }

    public func run(arguments: [String]) throws {
        console.info("Started the seeder")

        let user = try AdminPanelUser(
            name: "Admin",
            title: "Default admin account",
            email: "admin@admin.com",
            password: "admin",
            role: "Super Admin",
            shouldResetPassword: false,
            avatar: nil
        )

        try user.save()

        console.info("Finished the seeder");
    }
}
