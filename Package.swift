// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift Package Manager required to build this package.

import PackageDescription

let package = Package(
    name: "MeowPassword",
    targets: [
        .executableTarget(
            name: "meowpass",
            path: "Sources/MeowPassword"
        )
    ]
)
