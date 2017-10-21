import Flash
import Vapor
import Storage
import Sessions
import AuthProvider
import LeafProvider
import Leaf
import AuditProvider
import Paginator

public final class Provider: Vapor.Provider {
    public static let repositoryName = "nodes-vapor/admin-panel-provider"
    public var panelConfig: PanelConfig

    public init(panelConfig: PanelConfig) {
        self.panelConfig = panelConfig
    }

    public convenience init(config: Config) throws {
        var panelName = "Admin Panel"
        var baseUrl = "127.0.0.1:8080"
        var skin: PanelConfig.Skin = .blue
        var isEmailEnabled = true
        var isStorageEnabled = true
        var fromEmail: String?
        var fromName: String?

        if let config = config["mailgun"] {
            guard let email = config["fromAddress"]?.string else {
                throw ConfigError.missing(
                    key: ["fromAddress"],
                    file: "mailgun",
                    desiredType: String.self
                )
            }

            fromEmail = email

            guard let name = config["fromName"]?.string else {
                throw ConfigError.missing(
                    key: ["fromName"],
                    file: "mailgun",
                    desiredType: String.self
                )
            }

            fromName = name
        } else {
            print("WARNING: couldn't find `mailgun.json`. Email features will be disabled.")
            isEmailEnabled = false
        }

        if config["storage"] != nil {
            // only add storage if it hasn't been added yet
            if !config.providers
                .contains(where: { type(of: $0).repositoryName == "Storage" })
            {
                try config.addProvider(StorageProvider.self)
            }
        } else {
            print("WARNING: couldn't find `storage.json`. Image uploads will be disabled.")
            isStorageEnabled = false
        }

        if let adminConfig = config["adminpanel"] {
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
            fromEmail: fromEmail,
            fromName: fromName
        )
        self.init(panelConfig: panelConfig)
    }

    public func boot(_ config: Config) throws {
        try Middlewares.unsecured.append(PanelConfigMiddleware(panelConfig))
        Middlewares.unsecured.append(SessionsMiddleware(MemorySessions()))
        Middlewares.unsecured.append(PersistMiddleware(AdminPanelUser.self))
        Middlewares.unsecured.append(FlashMiddleware())
        Middlewares.unsecured.append(FieldsetMiddleware())
        Middlewares.unsecured.append(ActivityMiddleware())

        Middlewares.secured = Middlewares.unsecured
        Middlewares.secured.append(ProtectMiddleware())
        Middlewares.secured.append(PasswordAuthenticationMiddleware(AdminPanelUser.self))

        config.preparations.append(AdminPanelUser.self)
        config.preparations.append(AdminPanelUserResetToken.self)
        config.preparations.append(Action.self)

        config.addConfigurable(command: Seeder.init, name: "admin-panel:seeder")
        try config.addProvider(AuditProvider.Provider.self)
        try config.addProvider(PaginatorProvider.self)
    }

    public func boot(_ droplet: Droplet) throws {
        if let leaf = droplet.view as? LeafRenderer {
            registerLeafTags(leaf)
        }

        let renderer = droplet.view

        let mailgun: Mailgun?
        if panelConfig.isEmailEnabled {
            mailgun = try Mailgun(config: droplet.config)
        } else {
            mailgun = nil
        }

        let loginController = LoginController(
            renderer: renderer,
            mailgun: mailgun,
            panelConfig: panelConfig
        )

        let loginCollection = LoginRoutes(controller: loginController)
        try droplet.collection(loginCollection)

        let panelRoutes = PanelRoutes(
            renderer: renderer,
            mailgun: mailgun,
            panelConfig: panelConfig
        )
        try droplet.collection(panelRoutes)

        let bUserRoutes = AdminPanelUserRoutes(
            renderer: renderer,
            env: droplet.config.environment,
            mailgun: mailgun,
            panelConfig: panelConfig
        )

        try droplet.collection(bUserRoutes)
    }

    public func beforeRun(_ droplet: Droplet) throws {}
}

extension Provider {
    public func registerLeafTags(_ renderer: LeafRenderer) {
        let stem = renderer.stem
        stem.register(Box())
        stem.register(BoxBody())
        stem.register(BoxClose())
        stem.register(BoxFooter())
        stem.register(BoxOpen())
        stem.register(ButtonDelete())
        stem.register(CheckboxGroup())
        stem.register(ColorGroup())
        stem.register(DateGroup())
        stem.register(EmailGroup())
        stem.register(FormClose())
        stem.register(FormOpen())
        stem.register(GateAllow())
        stem.register(IfNotEmpty())
        stem.register(ImageRound())
        stem.register(InfoBox())
        stem.register(Label())
        stem.register(MenuFooter())
        stem.register(MenuToggle())
        stem.register(PasswordGroup())
        stem.register(SelectGroup())
        stem.register(SidebarContainer())
        stem.register(SidebarHeader())
        stem.register(SidebarLink())
        stem.register(SolidBox())
        stem.register(Table())
        stem.register(TableRows())
        stem.register(TextAreaGroup())
        stem.register(TextGroup())
        stem.register(TimeSince())
        stem.register(WYSIWYG())
    }
}
