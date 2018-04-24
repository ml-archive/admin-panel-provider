import Vapor

public enum Middlewares {
    public static var unsecured: [Middleware] = []
    public static var secured: [Middleware] = []
}
