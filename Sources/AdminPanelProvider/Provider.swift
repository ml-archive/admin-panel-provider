import Vapor
import LeafProvider
import StencilProvider

public final class Provider: Vapor.Provider {
    public static let repositoryName = "nodes-vapor/admin-panel-provider"

    public init() {}

    public convenience init(config: Config) throws {
        self.init()
    }

    public func boot(_ config: Config) throws {}

    public func boot(_ droplet: Droplet) throws {
        if let leaf = droplet.view as? LeafRenderer {
            setupLeafRenderer(leaf)
        } else if let stencil = droplet.view as? StencilRenderer {
            setupStencilRenderer(stencil)
        }
    }

    public func beforeRun(_ droplet: Droplet) throws {}
}

extension Provider {
    public func setupLeafRenderer(_ renderer: LeafRenderer) {

    }

    public func setupStencilRenderer(_ renderer: StencilRenderer) {

    }
}
