// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift Package Manager required to build this package.

import PackageDescription

let package = Package(
    name: "MeowPassword",
    platforms: [
        .macOS(.v13),
        .iOS(.v17)
    ],
    products: [
        .library(name: "MeowStego", targets: ["MeowStego"]),
        .library(name: "MeowGramKit", targets: ["MeowGramKit"]),
        .library(name: "MeowGramAssets", targets: ["MeowGramAssets"]),
        .library(name: "MeowPassCore", targets: ["MeowPassCore"]),
        .library(name: "MeowUI", targets: ["MeowUI"]),
        .library(name: "MeowThemeStore", targets: ["MeowThemeStore"])
    ],
    targets: [
        // MeowStego: DCT-domain steganography library for cat-image passkeys.
        // Pure Swift/Foundation — cross-platform.
        .target(
            name: "MeowStego",
            path: "Sources/MeowStego"
        ),
        // MeowPassCore: platform-independent password generation, complexity
        // analysis, cat names, and the voice-friendly meow-key.
        .target(
            name: "MeowPassCore",
            path: "Sources/MeowPassCore"
        ),
        // MeowGramKit: color image I/O + high-level MeowGram embed/decode.
        // Code-only (no bundled images) so decode-only clients (the share
        // extension) stay small. macOS + iOS (CoreGraphics/CryptoKit).
        .target(
            name: "MeowGramKit",
            dependencies: ["MeowStego"],
            path: "Sources/MeowGramKit"
        ),
        // MeowGramAssets: the 100 keyed cat PNGs + their catalog. Only clients
        // that show the picker (the apps, the iMessage extension) link this —
        // the decode share extension does not, keeping it lean.
        .target(
            name: "MeowGramAssets",
            path: "Sources/MeowGramAssets",
            resources: [
                .copy("Meowgrams"),
                // Theme-specific sets: Meowgrams-<Set> (Theme.meowgramSet).
                .copy("Meowgrams-Soviet")
            ]
        ),
        // MeowUI: portable SwiftUI design system shared by both apps.
        .target(
            name: "MeowUI",
            path: "Sources/MeowUI"
        ),
        // MeowThemeStore: StoreKit 2 purchases for theme packs. Linked by the
        // two APP targets only — extensions never talk to StoreKit; they read
        // ownership from the App Group defaults via ThemeManager.
        .target(
            name: "MeowThemeStore",
            dependencies: ["MeowUI"],
            path: "Sources/MeowThemeStore"
        ),
        .executableTarget(
            name: "meowpass",
            dependencies: ["MeowStego", "MeowGramKit", "MeowPassCore"],
            path: "Sources/MeowPassword",
            linkerSettings: [
                .linkedFramework("Security", .when(platforms: [.macOS]))
            ]
        ),
        .executableTarget(
            name: "MeowPasswordApp",
            dependencies: ["MeowStego", "MeowGramKit", "MeowGramAssets", "MeowPassCore", "MeowUI", "MeowThemeStore"],
            path: "Sources/MeowPasswordApp",
            exclude: [
                "Resources",
                "Assets/AppIcon.icns",
                "Assets/icon_1024.png",
                // The macOS App Store asset catalog is compiled by the XcodeGen
                // MeowPasswordMac target (ASSETCATALOG_COMPILER_APPICON_NAME);
                // the SwiftPM CLI/app build doesn't need an app icon.
                "Assets.xcassets"
            ],
            resources: [
                .process("Assets"),
                .process("Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "MeowUITests",
            dependencies: ["MeowUI"],
            path: "Tests/MeowUITests"
        ),
        .testTarget(
            name: "MeowStegoTests",
            dependencies: ["MeowStego"],
            path: "Tests/MeowStegoTests"
        ),
        .testTarget(
            name: "MeowPassCoreTests",
            dependencies: ["MeowPassCore"],
            path: "Tests/MeowPassCoreTests"
        ),
        .testTarget(
            name: "MeowPasswordAppTests",
            dependencies: ["MeowPasswordApp"],
            path: "Tests/MeowPasswordAppTests"
        )
    ]
)
