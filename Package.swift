// swift-tools-version:4.0

import PackageDescription

let package = Package(
        name: "valence-server",
        products: [
            .library(name: "App", targets: ["App"]),
            .executable(name: "Run", targets: ["Run"]),
            .executable(name: "Ingest", targets: ["Ingest"])
        ],
        dependencies: [
            .package(url: "https://github.com/vapor/vapor.git", from: "2.2.0"),
            .package(url: "https://github.com/vapor/fluent-provider.git", from: "1.2.0"),
            .package(url: "https://github.com/vapor-community/postgresql-provider.git",
                     from: "2.1.0"),
            .package(url: "https://github.com/Coder-256/Regex.git", from: "2.0.0-alpha.0"),
            .package(url: "https://github.com/alextdavis/tilt-provider.git", from: "0.1.1"),
            .package(url: "https://github.com/jkandzi/Progress.swift.git", from: "0.2.0"),
        ],
        targets: [
            .target(name: "App",
                    dependencies: [
                        "Vapor",
                        "FluentProvider",
                        "PostgreSQLProvider",
                        "Regex",
                        "TiltProvider",
                        "Progress",
                    ],
                    exclude: ["Config",
                              "Localization",
                              "Public",
                              "Resources",
                    ]),
            .target(name: "Run", dependencies: ["App"]),
            .target(name: "Ingest", dependencies: ["App"]),
        ]
)

