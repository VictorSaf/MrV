// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MrVAgent",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MrVAgent",
            targets: ["MrVAgent"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MrVAgent",
            dependencies: [],
            path: "MrVAgent",
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
