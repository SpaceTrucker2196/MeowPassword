// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "MeowPassword",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        .executable(name: "meowpass", targets: ["MeowPassword"]),
        .library(name: "MeowPasswordCore", targets: ["MeowPasswordCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "MeowPassword",
            dependencies: [
                "MeowPasswordCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            resources: [
                .copy("catNamesText.txt")
            ]
        ),
        .target(
            name: "MeowPasswordCore",
            dependencies: []
        ),
        .testTarget(
            name: "MeowPasswordTests",
            dependencies: ["MeowPasswordCore", "MeowPassword"]
        ),
    ]
)