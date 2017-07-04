import PackageDescription

let package = Package(
    name: "vtunes",
    targets: [
        Target(name: "App"),
        Target(name: "Run", dependencies: ["App"]),
        Target(name: "Ingest", dependencies: ["App"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/fluent-provider.git", majorVersion: 1),
        .Package(url: "https://github.com/vapor-community/postgresql-provider.git", majorVersion: 2),
        .Package(url: "https://github.com/crossroadlabs/Regex.git", majorVersion: 1),
        .Package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", majorVersion: 0),
        .Package(url: "https://github.com/alextdavis/tilt-provider", majorVersion: 0),
        
    ],
    exclude: [
        "Config",
        "Database",
        "Localization",
        "Public",
        "Resources",
    ]
)

