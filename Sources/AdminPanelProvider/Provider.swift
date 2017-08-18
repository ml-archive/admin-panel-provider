import Flash
import Vapor
import Stencil
import Storage
import Sessions
import AuthProvider
import LeafProvider
import StencilProvider

public final class Provider: Vapor.Provider {
    public static let repositoryName = "nodes-vapor/admin-panel-provider"
    public var config: PanelConfig!

    public init() {}

    public convenience init(config: Config) throws {
        self.init()
    }

    public func boot(_ config: Config) throws {
        var panelName = "Admin Panel"
        var skin: PanelConfig.Skin = .blue
        var isEmailEnabled = true
        var isStorageEnabled = false

        if config["mail"] == nil {
            print("WARNING: couldn't find `mail.json`. Email features will be disabled")
            isEmailEnabled = false
        }

        if let adminConfig = config["admin"] {
            panelName = adminConfig["name"]?.string ?? panelName
            if
                let userSkinConfig = adminConfig["skin"]?.string,
                let userSkin = PanelConfig.Skin(rawValue: userSkinConfig)
            {
                skin = userSkin
            }
        }

        let panelConfig = PanelConfig(
            panelName: panelName,
            skin: skin,
            isEmailEnabled: isEmailEnabled,
            isStorageEnabled: isStorageEnabled
        )

        self.config = panelConfig

        try Middlewares.unsecured.append(PanelConfigMiddleware(panelConfig))
        Middlewares.unsecured.append(SessionsMiddleware(MemorySessions()))
        Middlewares.unsecured.append(PersistMiddleware(BackendUser.self))
        Middlewares.unsecured.append(FlashMiddleware())
        Middlewares.unsecured.append(FieldsetMiddleware())
        Middlewares.unsecured.append(ActionMiddleware())

        Middlewares.secured = Middlewares.unsecured
        Middlewares.secured.append(RedirectMiddleware(path: "/admin/login"))
        Middlewares.secured.append(PasswordAuthenticationMiddleware(BackendUser.self))

        config.preparations.append(BackendUser.self)
        config.preparations.append(Action.self)

        config.addConfigurable(command: Seeder.init, name: "admin-panel:seeder")
    }

    public func boot(_ droplet: Droplet) throws {
        if let leaf = droplet.view as? LeafRenderer {
            setupLeafRenderer(leaf)
        } else if let stencil = droplet.view as? StencilRenderer {
            setupStencilRenderer(stencil)
        }

        let renderer = droplet.view
        let loginCollection = LoginRoutes(renderer: renderer)
        try droplet.collection(loginCollection)

        let panelRoutes = PanelRoutes(renderer: renderer)
        try droplet.collection(panelRoutes)

        let bUserRoutes = BackendUserRoutes(
            renderer: renderer,
            env: droplet.config.environment,
            isEmailEnabled: config.isEmailEnabled,
            isStorageEnabled: config.isStorageEnabled
        )

        try droplet.collection(bUserRoutes)
    }

    public func beforeRun(_ droplet: Droplet) throws {}
}

extension Provider {
    public func setupLeafRenderer(_ renderer: LeafRenderer) {
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
    }

    public func setupStencilRenderer(_ renderer: StencilRenderer) {
        
    }
}
