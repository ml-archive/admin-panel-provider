import PackageDescription

let package = Package(
    name: "AdminPanelProvider",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/jwt.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/leaf-provider.git", majorVersion: 1),
        .Package(url: "https://github.com/BrettRToomey/stencil-provider.git", majorVersion: 0)
    ]
)
