import Flash
import Vapor
import Stencil
import Sessions
import LeafProvider
import StencilProvider

public final class Provider: Vapor.Provider {
    public static let repositoryName = "nodes-vapor/admin-panel-provider"

    public init() {}

    public convenience init(config: Config) throws {
        self.init()
    }

    public func boot(_ config: Config) throws {
        try Middlewares.unsecured.append(PanelConfigMiddleware(panelName: "Nodes Admin", skin: .black))
        Middlewares.unsecured.append(SessionsMiddleware(MemorySessions()))
        Middlewares.unsecured.append(FlashMiddleware())
        Middlewares.unsecured.append(FieldsetMiddleware())
        // TODO: add config check for actions and tracking
        Middlewares.unsecured.append(ActionMiddleware())

        Middlewares.secured = Middlewares.unsecured

        config.preparations.append(BackendUser.self)
        config.preparations.append(Action.self)
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

        let bUserRoutes = BackendUserRoutes(renderer: renderer, env: droplet.config.environment)
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
    }

    public func setupStencilRenderer(_ renderer: StencilRenderer) {
        
    }
}
