import Flash
import Vapor
import Storage
import Sessions
import AuthProvider
import LeafProvider
import Leaf

public final class Provider: Vapor.Provider {
    public static let repositoryName = "nodes-vapor/admin-panel-provider"
    public var config: PanelConfig!

    public init() {}

    public convenience init(config: Config) throws {
        self.init()
    }

    public func boot(_ config: Config) throws {
        var panelName = "Admin Panel"
        var baseUrl = "127.0.0.1:8080"
        var skin: PanelConfig.Skin = .blue
        var isEmailEnabled = true
        var isStorageEnabled = true
        var fromEmail: String?

        if let config = config["mailgun"] {
            guard let email = config["fromAddress"]?.string else {
                throw ConfigError.missing(key: ["fromAddress"], file: "mailgun.json", desiredType: String.self)
            }

            fromEmail = email
        } else {
            print("WARNING: couldn't find `mailgun.json`. Email features will be disabled")
            isEmailEnabled = false
        }

        if config["storage"] != nil {
            // only add storage if it hasn't been added yet
            if !config.providers.contains(where: { type(of: $0).repositoryName == "Storage" }) {
                try config.addProvider(StorageProvider.self)
            }
        } else {
            print("WARNING: couldn't find `storage.json`. Image uploads will be disabled")
            isStorageEnabled = false
        }

        if let adminConfig = config["admin"] {
            panelName = adminConfig["name"]?.string ?? panelName
            if
                let userSkinConfig = adminConfig["skin"]?.string,
                let userSkin = PanelConfig.Skin(rawValue: userSkinConfig)
            {
                skin = userSkin
            }

            if let url = adminConfig["baseUrl"]?.string {
                baseUrl = url
            }
        }

        let panelConfig = PanelConfig(
            panelName: panelName,
            baseUrl: baseUrl,
            skin: skin,
            isEmailEnabled: isEmailEnabled,
            isStorageEnabled: isStorageEnabled,
            fromEmail: fromEmail
        )

        self.config = panelConfig

        try Middlewares.unsecured.append(PanelConfigMiddleware(panelConfig))
        Middlewares.unsecured.append(SessionsMiddleware(MemorySessions()))
        Middlewares.unsecured.append(PersistMiddleware(User.self))
        Middlewares.unsecured.append(FlashMiddleware())
        Middlewares.unsecured.append(FieldsetMiddleware())
        Middlewares.unsecured.append(ActionMiddleware())

        Middlewares.secured = Middlewares.unsecured
        Middlewares.secured.append(ProtectMiddleware(path: "/admin/login"))
        Middlewares.secured.append(PasswordAuthenticationMiddleware(User.self))

        config.preparations.append(User.self)
        config.preparations.append(UserResetToken.self)
        config.preparations.append(Action.self)

        config.addConfigurable(command: Seeder.init, name: "admin-panel:seeder")
    }

    public func boot(_ droplet: Droplet) throws {
        if let leaf = droplet.view as? LeafRenderer {
            registerLeafTags(leaf)
        }

        let renderer = droplet.view

        let mailgun: Mailgun?
        if config.isEmailEnabled {
            mailgun = try Mailgun(config: droplet.config)
        } else {
            mailgun = nil
        }

        let loginController = LoginController(
            renderer: renderer,
            mailgun: mailgun,
            panelConfig: config
        )

        let loginCollection = LoginRoutes(controller: loginController)
        try droplet.collection(loginCollection)

        let panelRoutes = PanelRoutes(
            renderer: renderer,
            mailgun: mailgun,
            panelConfig: config
        )
        try droplet.collection(panelRoutes)

        let bUserRoutes = UserRoutes(
            renderer: renderer,
            env: droplet.config.environment,
            mailgun: mailgun,
            isEmailEnabled: config.isEmailEnabled,
            isStorageEnabled: config.isStorageEnabled
        )

        try droplet.collection(bUserRoutes)
    }

    public func beforeRun(_ droplet: Droplet) throws {}
}

extension Provider {
    public func registerLeafTags(_ renderer: LeafRenderer) {
        let stem = renderer.stem
        stem.register(IfNotEmpty())
        stem.register(FormOpen())
        stem.register(FormClose())
        stem.register(TextGroup())
        stem.register(EmailGroup())
        stem.register(PasswordGroup())
        stem.register(CheckboxGroup())
        stem.register(SelectGroup())
        stem.register(DateGroup())
        stem.register(ColorGroup())
        stem.register(WYSIWYG())
        stem.register(Box())
        stem.register(SolidBox())
        stem.register(BoxOpen())
        stem.register(BoxBody())
        stem.register(BoxFooter())
        stem.register(BoxClose())
        stem.register(InfoBox())
        stem.register(MenuToggle())
        stem.register(MenuFooter())
        stem.register(SidebarHeader())
        stem.register(SidebarLink())
        stem.register(SidebarContainer())
        stem.register(ImageRound())
        stem.register(Label())
        stem.register(Table())
        stem.register(TableRows())
        stem.register(GateAllow())
    }
}
