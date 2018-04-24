import Vapor
import Console

typealias Seeder = CustomUserSeeder<AdminPanelUser>

/// Seeds the admin panel with a default user
public final class CustomUserSeeder<U: AdminPanelUserType>: Command, ConfigInitializable {
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

        let user = try U.makeSeededUser()

        try user.save()

        console.info("Finished the seeder");
    }
}
