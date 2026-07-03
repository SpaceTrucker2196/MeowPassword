// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift Package Manager required to build this package.

import PackageDescription

let package = Package(
    name: "MeowPassword",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        // MeowStego: DCT-domain steganography library for cat-image passkeys.
        .target(
            name: "MeowStego",
            path: "Sources/MeowStego"
        ),
        .executableTarget(
            name: "meowpass",
            dependencies: ["MeowStego"],
            path: "Sources/MeowPassword",
            linkerSettings: [
                .linkedFramework("Security", .when(platforms: [.macOS]))
            ]
        ),
        .executableTarget(
            name: "MeowPasswordApp",
            path: "Sources/MeowPasswordApp",
            exclude: [
                "Resources",
                "Assets/AppIcon.icns",
                "Assets/icon_1024.png"
            ],
            resources: [.process("Assets")]
        ),
        .testTarget(
            name: "MeowStegoTests",
            dependencies: ["MeowStego"],
            path: "Tests/MeowStegoTests"
        )
    ]
)
