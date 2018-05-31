import XCTest
import Vapor
import Testing
import Leaf
import LeafProvider

@testable import AdminPanelProvider

class AdminPanelProviderTests: XCTestCase {
    func testBasic() throws {
        let config = PanelConfig(
            panelName: "Admin",
            baseUrl: "127.0.0.1:8080",
            skin: .black,
            isEmailEnabled: false,
            isStorageEnabled: false,
            fromEmail: nil,
            fromName: nil,
            passwordEditPathForUser: nil
        )
        let controller = LoginController(
            renderer: LeafTestRenderer(viewsDir: workingDirectory() + "/Resources/Views/"),
            mailer: nil,
            panelConfig: config
        )
        let response = try controller.landing(
            req: Request(method: .get, uri: "/")
        )
    }
}

func testable() throws -> Droplet {
    let config = try Config(arguments: ["vapor", "--env=test"])
    let drop = try Droplet(
        config: config,
        view: CapturingViewRenderer())
    return drop
}

/// View Renderer to use for testing. Captures passed-in arguments.
class CapturingViewRenderer: ViewRenderer {
    var capturedData: ViewData?
    var capturedPath: String?

    var shouldCache = false

    func make(_ path: String, _ data: ViewData) throws -> View {
        self.capturedData = data
        self.capturedPath = path
        return View(data: [])
    }
}

final class LeafTestRenderer: ViewRenderer {
    var shouldCache: Bool
    let stem: Stem

    let context: CapturedContext

    init(viewsDir: String) {
        let file = DataFile(workDir: viewsDir)
        stem = Stem(file)
        shouldCache = false
        context = CapturedContext()
    }

    func make(_ path: String, _ data: Node) throws -> View {
        stem.register(TestableIf(renderer: self))
        stem.register(FormOpen())
        stem.register(FormClose())
        stem.register(TextGroup())
        return try self.make(path, Context(data))
    }

    func make(_ path: String, _ context: LeafContext) throws -> View {
        let leaf = try stem.spawnLeaf(at: path)
        let bytes = try stem.render(leaf, with: context)
        return View(data: bytes)
    }
}

class CapturedContext {
    var ifStatements: [TestableIf.Context]
    var loopStatements: [TestableLoop.Context]
    
    init() {
        ifStatements = []
        loopStatements = []
    }
}
