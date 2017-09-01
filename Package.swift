import PackageDescription

let package = Package(
    name: "AdminPanelProvider",
    dependencies: [
        // Vapor
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/leaf-provider.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/mysql-provider.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/auth-provider.git", majorVersion: 1),

        // Nodes
        .Package(url: "https://github.com/nodes-vapor/flash.git", majorVersion: 1),
        .Package(url: "https://github.com/nodes-vapor/slugify.git", majorVersion: 1),
        .Package(url: "https://github.com/nodes-vapor/storage.git", majorVersion: 0),
        .Package(url: "https://github.com/nodes-vapor/paginator.git", majorVersion: 1),
    ]
)
