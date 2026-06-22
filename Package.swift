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
        // Pinned to the highest 0.x tag that still targets macOS 13 (Ventura).
        // WhisperKit 1.0.0+ requires macOS 14, which would drop Ventura support.
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", exact: "0.18.0"),
    ],
    targets: [
        .executableTarget(
            name: "Elvistelefon",
            dependencies: [
                "KeyboardShortcuts",
                .product(name: "WhisperKit", package: "whisperkit"),
            ],
            path: "Sources/Elvistelefon",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
