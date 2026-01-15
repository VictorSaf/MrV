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
            exclude: ["MrVAgent.entitlements", "Info.plist"],
            resources: [
                .process("Assets.xcassets"),
                .process("Metal/Shaders")
            ]
        )
    ]
)
