// Sources/MeowUI/Theme.swift
//
// The semantic theme contract from docs/themes/README.md: six color roles
// (Floor, Command, Celebrate, Cool, Bind, Seal) plus support tokens, applied
// app-wide through the SwiftUI environment. Every theme — free or paid — is a
// value of `Theme`; views read `@Environment(\.theme)` and never name a
// concrete palette.

import SwiftUI

// MARK: - Palette

/// Raw color values for one theme. Hexes are stored as `0xRRGGBB` integers so
/// tests can assert byte-exact parity with the specs in `docs/themes/`.
public struct ThemePalette: Equatable, Sendable {
    /// Dominant background (~60% of any screen).
    public let floor: UInt32
    /// The shout: headline plates, primary CTA, the seal's family.
    public let command: UInt32
    /// Deeper command variant (magenta / star red / hanko red).
    public let commandDeep: UInt32
    /// Bursts, highlights, secondary accents.
    public let celebrate: UInt32
    /// The single cool accent per composition.
    public let cool: UInt32
    /// Outlines, text, hard offset shadows.
    public let bind: UInt32
    /// The circular approval stamp.
    public let seal: UInt32
    /// Readable card/panel fill (paper, dossier).
    public let surface: UInt32
    /// Body text sitting directly on the floor.
    public let textOnFloor: UInt32
    /// Text/glyphs on command-colored plates (buttons, banners, headline
    /// plates). White on tomato/pink; near-black on champagne gold.
    public let textOnCommand: UInt32
    /// Success accents (decode OK, "GOT IT!"). May coincide with another role.
    public let positive: UInt32
    /// Errors and alerts. Rare by every theme's quota.
    public let danger: UInt32
    /// Strength-meter gradient stops, left to right.
    public let meterStops: [UInt32]

    public init(floor: UInt32, command: UInt32, commandDeep: UInt32,
                celebrate: UInt32, cool: UInt32, bind: UInt32, seal: UInt32,
                surface: UInt32, textOnFloor: UInt32, textOnCommand: UInt32,
                positive: UInt32, danger: UInt32, meterStops: [UInt32]) {
        self.floor = floor
        self.command = command
        self.commandDeep = commandDeep
        self.celebrate = celebrate
        self.cool = cool
        self.bind = bind
        self.seal = seal
        self.surface = surface
        self.textOnFloor = textOnFloor
        self.textOnCommand = textOnCommand
        self.positive = positive
        self.danger = danger
        self.meterStops = meterStops
    }
}

// MARK: - Theme

public struct Theme: Identifiable, Equatable, Sendable {
    /// Stable identifiers — persisted to UserDefaults and mapped to StoreKit
    /// product IDs, so raw values must never change.
    public enum ID: String, CaseIterable, Codable, Sendable {
        case showa
        case gameShowClassic
        case spyThriller
        case kremlinCartoon
        case pyongyangPoster

        /// StoreKit product ID for paid packs; nil for free themes. The
        /// camelCase is a cross-platform SKU contract (docs/themes/README.md)
        /// — do not "normalize" it to match the bundle ID.
        public var productID: String? {
            switch self {
            case .showa, .gameShowClassic: return nil
            case .spyThriller:     return "io.river.meowPassword.spyThemePack"
            case .kremlinCartoon:  return "io.river.meowPassword.kremlinThemePack"
            case .pyongyangPoster: return "io.river.meowPassword.pyongyangThemePack"
            }
        }

        public var isFree: Bool { productID == nil }
    }

    /// Shape of the signature approval stamp (each theme doc's "Signature
    /// stamp" token).
    public enum SealStyle: Equatable, Sendable {
        /// Circular ink seal (Shōwa's hanko; Classic borrows it).
        case hanko
        /// Concentric gun-barrel rings (Spy Thriller).
        case iris
        /// Five-point star (Kremlin Cartoon).
        case star
        /// Flower-burst rosette (Pyongyang Poster).
        case rosette
    }

    /// Background treatment, one per theme (docs name these "background motifs").
    public enum Motif: Equatable, Sendable {
        /// Shōwa: flat cream + sunburst wedge fan + halftone dots.
        case sunburstHalftone
        /// GameShow Classic: the original pink→purple neon gradient.
        case neonGradient
        /// Spy: flat tuxedo black + gold glint diagonal + faint reticle grid.
        case reticleNight
        /// Kremlin: newsprint + angular red wedge rays.
        case wedgeRays
        /// Pyongyang: dawn rose + gold beam fan + the one permitted soft glow.
        case sunrise
    }

    public let id: ID
    /// English display string, used as the localization key.
    public let nameKey: String
    public let palette: ThemePalette
    /// Themes pick their own scheme (the print aesthetic never follows the OS
    /// setting); only Spy Thriller is dark.
    public let prefersDark: Bool
    public let motif: Motif
    public let sealStyle: SealStyle
    /// Text inside the signature approval stamp.
    public let sealCaption: String

    public init(id: ID, nameKey: String, palette: ThemePalette,
                prefersDark: Bool, motif: Motif, sealStyle: SealStyle,
                sealCaption: String) {
        self.id = id
        self.nameKey = nameKey
        self.palette = palette
        self.prefersDark = prefersDark
        self.motif = motif
        self.sealStyle = sealStyle
        self.sealCaption = sealCaption
    }

    public var colorScheme: ColorScheme { prefersDark ? .dark : .light }

    // Semantic color accessors — what views actually use.
    public var floor: Color        { Color(hex: palette.floor) }
    public var command: Color      { Color(hex: palette.command) }
    public var commandDeep: Color  { Color(hex: palette.commandDeep) }
    public var celebrate: Color    { Color(hex: palette.celebrate) }
    public var cool: Color         { Color(hex: palette.cool) }
    public var bind: Color         { Color(hex: palette.bind) }
    public var seal: Color         { Color(hex: palette.seal) }
    public var surface: Color      { Color(hex: palette.surface) }
    public var textOnFloor: Color  { Color(hex: palette.textOnFloor) }
    public var textOnCommand: Color { Color(hex: palette.textOnCommand) }
    public var positive: Color     { Color(hex: palette.positive) }
    public var danger: Color       { Color(hex: palette.danger) }

    /// Strength-meter gradient, left to right.
    public var meter: LinearGradient {
        LinearGradient(colors: palette.meterStops.map { Color(hex: $0) },
                       startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Color(hex:)

public extension Color {
    /// `Color(hex: 0xF4E9CE)` — sRGB, full opacity.
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255.0,
                  green: Double((hex >> 8) & 0xFF) / 255.0,
                  blue: Double(hex & 0xFF) / 255.0)
    }
}

// MARK: - Environment

private struct ThemeKey: EnvironmentKey {
    // Shōwa Broadcast is the house default (docs/themes/README.md). Keep in
    // sync with ThemeManager.defaultThemeID.
    static let defaultValue: Theme = .showa
}

public extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
