import Vapor
import Cookies
import AuthProvider

public final class LoginController {
    public let renderer: ViewRenderer
    public let mailgun: Mailgun?
    public let panelConfig: PanelConfig

    public init(
        renderer: ViewRenderer,
        mailgun: Mailgun?,
        panelConfig: PanelConfig
    ) {
        self.renderer = renderer
        self.mailgun = mailgun
        self.panelConfig = panelConfig
    }

    public func login(req: Request) throws -> ResponseRepresentable {
        do {
            guard
                let username = req.data["email"]?.string,
                let password = req.data["password"]?.string
            else {
                return redirect("/admin/login").flash(.error, "Invalid username and/or password")
            }

            let credentials = Password(username: username, password: password)
            let user = try User.authenticate(credentials)

            let shouldPersist = req.data["rememberMe"] != nil
            try req.auth.authenticate(user, persist: shouldPersist)
            if shouldPersist {
//                req.cookies.insert(
//                    Cookie.init(
//                        name: "rememberMe",
//                        value: <#T##String#>,
//                        expires: Date().addingTimeInterval(5_184_000)
//                    )
//                )
            }

            var redir = "/admin/dashboard"
            if let next = req.query?["next"]?.string, !next.isEmpty {
                redir = next
            }

            return redirect(redir).flash(.success, "Logged in as \(username)")
        } catch {
            return redirect("/admin/login").flash(.error, "Invalid username and/or password")
        }
    }

    public func landing(req: Request) throws -> ResponseRepresentable {
        let next = req.query?["next"]

        return try renderer.make(
            "Login/index",
            [
                "collapse": "true",
                "next": next
            ],
            for: req
        )
    }

    public func resetPassword(req: Request) throws -> ResponseRepresentable {
        return try renderer.make("Login/reset", for: req)
    }

    public func resetPasswordSubmit(req: Request) throws -> ResponseRepresentable {
        do {
            guard
                let email = req.data["email"]?.string,
                let user = try User.makeQuery().filter("email", email).first()
            else {
                return redirect("/admin/login").flash(.success, "E-mail with instructions sent if user exists")
            }

            try UserResetToken.makeQuery().filter("email", email).delete()

            let randomString = String.random(64)
            let token = UserResetToken(email: email, token: randomString, expireAt: Date().addingTimeInterval(60*60))
            try token.save()
            
            if let fromEmail = panelConfig.fromEmail {
                mailgun?.sendEmail(
                    from: fromEmail,
                    to: email,
                    subject: "Reset password",
                    path: "Emails/reset-password",
                    renderer: renderer,
                    context: [
                        "name": .string(panelConfig.panelName),
                        "user": try user.makeViewData(),
                        "url": .string(panelConfig.baseUrl),
                        "token": .string(token.token),
                        "expire": 60
                    ]
                )
            }

            return redirect("/admin/login").flash(.success, "E-mail with instructions sent if user exists")
        } catch {
            return redirect("/admin/login/reset").flash(.error, "An error occured")
        }
    }

    public func resetPasswordToken(req: Request) throws -> ResponseRepresentable {
        let tokenParam = try req.parameters.next(String.self)

        guard
            let token = try UserResetToken.makeQuery().filter("token", tokenParam).first(),
            token.canBeUsed
        else {
            return redirect("/admin/login").flash(.error, "Token does not exist")
        }

        return try renderer.make("ResetPassword/form", ["token": token.token], for: req)
    }

    public func resetPasswordTokenSubmit(req: Request) throws -> ResponseRepresentable {
        guard
            let tokenParam = req.data["token"]?.string,
            let email = req.data["email"]?.string,
            let password = req.data["password"]?.string,
            let passwordRepeat = req.data["passwordRepeat"]?.string
        else {
            return redirect("/admin/login").flash(.error, "Invalid request")
        }

        guard
            let token = try UserResetToken.makeQuery().filter("token", tokenParam).first(),
            token.canBeUsed
        else {
            return redirect("/admin/login").flash(.error, "Token does not exist")
        }

        if token.email != email {
            return redirect("/admin/login").flash(.error, "Token is not valid for given email")
        }

        if password != passwordRepeat {
            return redirect("/admin/login/reset/" + tokenParam).flash(.error, "Passwords do not match")
        }

        guard let user = try User.makeQuery().filter("email", email).first() else {
            return redirect("/admin/login").flash(.error, "User not found")
        }

        try user.updatePassword(password)
        try token.use()
        return redirect("/admin/login").flash(.success, "Password reset")
    }

    public func dashboard(req: Request) throws -> ResponseRepresentable {
        let ordersData: [Node] = [
            Node([
                "id": "OR9842",
                "title": "Call of Duty IV",
                "status": Node(["value": "Shipped", "type": "success"])
            ]),
            Node([
                "id": "OR9842",
                "title": "Call of Duty IV",
                "status": Node(["value": "Shipped", "type": "success"])
            ]),
            Node([
                "id": "OR1848",
                "title": "Samsung Smart TV",
                "status": Node(["value": "Pending", "type": "warning"])
            ]),
            Node([
                "id": "OR9842",
                "title": "Call of Duty IV",
                "status": Node(["value": "Cancelled", "type": "danger"])
            ]),
            Node([
                "id": "OR9842",
                "title": "Call of Duty IV",
                "status": Node(["value": "Shipped", "type": "success"])
            ])
        ]

        let orders = Node(ordersData)
        return try renderer.make("Dashboard/index", ["orders": orders], for: req)
    }
}
