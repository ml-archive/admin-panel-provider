import PackageDescription

let package = Package(
    name: "AdminPanelProvider",
    dependencies: [
        // Vapor
        .Package(url: "https://github.com/vapor/jwt.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/leaf-provider.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/mysql-provider.git", majorVersion: 2),

        // Nodes
        .Package(url: "https://github.com/nodes-vapor/flash.git", majorVersion: 1),
        .Package(url: "https://github.com/nodes-vapor/slugify.git", majorVersion: 1),
        .Package(url: "https://github.com/nodes-vapor/paginator.git", majorVersion: 1),

        // Brett
        .Package(url: "https://github.com/BrettRToomey/stencil-provider.git", majorVersion: 0),
    ]
)
