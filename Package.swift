// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Elvistelefon",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Elvistelefon", targets: ["Elvistelefon"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Elvistelefon",
            dependencies: [
                "KeyboardShortcuts",
            ],
            path: "Sources/Elvistelefon",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
