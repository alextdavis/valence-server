import PackageDescription

let package = Package(
    name: "vtunes",
    targets: [
        Target(name: "App"),
        Target(name: "Run", dependencies: ["App"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/vapor/fluent-provider.git", Version(1,0,0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "https://github.com/vapor/mysql-provider.git", Version(2,0,0, prereleaseIdentifiers: ["beta"])),
        .Package(url: "../erb-provider", majorVersion: 0),
    ],
    exclude: [
        "Config",
        "Database",
        "Localization",
        "Public",
        "Resources",
    ]
)

