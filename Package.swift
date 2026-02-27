// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift Package Manager required to build this package.

import PackageDescription

let package = Package(
    name: "MeowPassword",
    targets: [
        // MeowStego: DCT-domain steganography library for cat-image passkeys.
        .target(
            name: "MeowStego",
            path: "Sources/MeowStego"
        ),
        .executableTarget(
            name: "meowpass",
            dependencies: ["MeowStego"],
            path: "Sources/MeowPassword"
        ),
        .testTarget(
            name: "MeowStegoTests",
            dependencies: ["MeowStego"],
            path: "Tests/MeowStegoTests"
        )
    ]
)
