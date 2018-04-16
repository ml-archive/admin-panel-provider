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
        let fileName = "adminpanel"

        if let config = config[fileName, "email"] {
            guard let email = config["fromAddress"]?.string else {
                throw ConfigError.missing(
                    key: ["fromAddress"],
                    file: fileName,
                    desiredType: String.self
                )
            }

            guard let name = config["fromName"]?.string else {
                throw ConfigError.missing(
                    key: ["fromName"],
                    file: fileName,
                    desiredType: String.self
                )
            }

            fromEmail = email
            fromName = name
        } else {
            print("WARNING: couldn't find `email` key in `\(fileName).json`. Email features will be disabled.")
            isEmailEnabled = false
        }

        if let config = config[fileName] {
            panelName = config["name"]?.string ?? panelName
            baseUrl = config["baseUrl"]?.string ?? baseUrl

            if let userSkinConfig = config["skin"]?.string {
                skin = PanelConfig.Skin(rawValue: userSkinConfig) ?? skin
            }
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
        //Middlewares.unsecured.append(SessionsMiddleware(MemorySessions()))
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

        let mailer: MailProtocol?
        if panelConfig.isEmailEnabled {
            mailer = droplet.mail
        } else {
            mailer = nil
        }

        let loginController = LoginController(
            renderer: renderer,
            mailer: mailer,
            panelConfig: panelConfig
        )

        let loginCollection = LoginRoutes(controller: loginController)
        try droplet.collection(loginCollection)

        let panelRoutes = PanelRoutes(
            renderer: renderer,
            mailer: mailer,
            panelConfig: panelConfig
        )
        try droplet.collection(panelRoutes)

        let bUserRoutes = AdminPanelUserRoutes(
            renderer: renderer,
            env: droplet.config.environment,
            mailer: mailer,
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
