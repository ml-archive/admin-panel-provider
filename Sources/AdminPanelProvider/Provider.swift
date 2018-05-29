import AuditProvider
import AuthProvider
import Flash
import Forms
import Leaf
import LeafProvider
import Paginator
import Sessions
import Vapor

public typealias Provider = CustomUserProvider<AdminPanelUser>

public final class CustomUserProvider<U: AdminPanelUserType>: Vapor.Provider {
    public static var repositoryName: String {
        return "nodes-vapor/admin-panel-provider"
    }
    public var panelConfig: PanelConfig

    public init(
        panelConfig: PanelConfig
    ) {
        self.panelConfig = panelConfig
    }

    public convenience init(config: Config) throws {
        let panelConfig = try PanelConfig(config: config)
        self.init(panelConfig: panelConfig)
    }

    public func boot(_ config: Config) throws {
        try Middlewares.unsecured.append(PanelConfigMiddleware(panelConfig))
        Middlewares.unsecured.append(PersistMiddleware<U>())
        Middlewares.unsecured.append(FlashMiddleware())
        Middlewares.unsecured.append(FieldsetMiddleware())
        Middlewares.unsecured.append(CustomUserActivityMiddleware<U>())

        Middlewares.secured = Middlewares.unsecured
        Middlewares.secured.append(
            CustomUserProtectMiddleware<U>(passwordEditPathForUser: panelConfig.passwordEditPathForUser)
        )
        Middlewares.secured.append(PasswordAuthenticationMiddleware<U>())

        config.preparations.append(U.self)
        config.preparations.append(AdminPanelUserResetToken.self)
        config.preparations.append(CustomUserAction<U>.self)

        config.addConfigurable(command: CustomUserSeeder<U>.init, name: "admin-panel:seeder")
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

        let loginController = CustomUserLoginController<U>(
            renderer: renderer,
            mailer: mailer,
            panelConfig: panelConfig
        )

        let loginCollection = CustomUserLoginRoutes<U>(controller: loginController)
        try droplet.collection(loginCollection)

        let panelRoutes = PanelRoutes(
            renderer: renderer,
            mailer: mailer,
            panelConfig: panelConfig
        )
        try droplet.collection(panelRoutes)

        let bUserRoutes = CustomAdminPanelUserRoutes<U>(
            renderer: renderer,
            env: droplet.config.environment,
            mailer: mailer,
            panelConfig: panelConfig
        )

        try droplet.collection(bUserRoutes)
    }

    public func beforeRun(_ droplet: Droplet) throws {}
}

extension CustomUserProvider {
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
