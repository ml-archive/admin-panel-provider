import SMTP
import Vapor

extension MailProtocol {
    /// A convenience for rendering emails with a template engine
    public func sendEmail(
        from: EmailAddressRepresentable,
        to: EmailAddressRepresentable,
        subject: String,
        path: String,
        renderer: ViewRenderer,
        context: ViewData
    ) {
        do {
            let template = try renderer.make(path, context)
            let email = Email(
                from: from,
                to: to,
                subject: subject,
                body: EmailBody(type: .html, content: template.makeBytes().makeString())
            )

            try send(email)
        } catch {
            // TODO: bugsnag?
            print(error)
        }
    }
}
