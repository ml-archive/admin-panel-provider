import HTTP
import XCTest
import Testing
import Authentication

@testable import AdminPanelProvider

class ProtectMiddlewareTests: XCTestCase {
    override func setUp() {
        Testing.onFail = XCTFail
    }

    func testUnauthenticatedRedirects() throws {
        let middleware = ProtectMiddleware()
        let response = try middleware.respondUnauthenticated()
        response
            .assertStatus(is: .seeOther)
            .assertHeader("Location", contains: "/admin/login?next=/admin/unauthenticated")
        print()
    }

    func testAuthenticatedDoesNotRedirect() throws {
        let middleware = ProtectMiddleware()
        let response = try middleware.respondAuthenticated()
        try response
            .assertStatus(is: .ok)
            .assertBody(equals: "Hello, world!")
    }
}

extension Request {
    static var authenticated: Request {
        return Request(method: .get, uri: "/admin/authenticated")
    }

    static var unauthenticated: Request {
        return Request(method: .get, uri: "/admin/unauthenticated")
    }
}

extension Middleware {
    func respondAuthenticated(_ req: Request = .authenticated) throws -> Response {
        let responder = BasicResponder({ req in return "Hello, world!".makeResponse() })
        return try respond(to: req, chainingTo: responder)
    }

    func respondUnauthenticated(_ req: Request = .unauthenticated) throws -> Response {
        let responder = BasicResponder({ _ in throw AuthenticationError.notAuthenticated })
        return try respond(to: req, chainingTo: responder)
    }
}
