import PackageDescription

let package = Package(
    name: "AdminPanelProvider",
    dependencies: [
        // Vapor
        .Package(url: "https://github.com/vapor/auth-provider.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/leaf-provider.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),

        // Nodes
        .Package(url: "https://github.com/nodes-vapor/flash.git", majorVersion: 1),
        .Package(url: "https://github.com/nodes-vapor/audit-provider.git", majorVersion: 0, minor: 1),
        .Package(url: "https://github.com/nodes-vapor/forms.git", majorVersion: 0, minor: 7),
        .Package(url: "https://github.com/nodes-vapor/paginator.git", majorVersion: 2, minor: 0),
        .Package(url: "https://github.com/nodes-vapor/slugify.git", majorVersion: 1),
        .Package(url: "https://github.com/nodes-vapor/storage.git", majorVersion: 0, minor: 4)
    ]
)
