// Sources/MeowUI/ThemeDefinitions.swift
//
// The five theme definitions. Color values are byte-exact to the specs:
//   Shōwa Broadcast   — docs/DESIGN.md ("Color — the quota")
//   GameShow Classic  — the original neon literals from MeowUI.swift
//   Spy Thriller      — docs/themes/spy-thriller.md
//   Kremlin Cartoon   — docs/themes/kremlin.md
//   Pyongyang Poster  — docs/themes/pyongyang.md
// Tests/MeowUITests/ThemeTests.swift asserts this file against those tables —
// change a hex only if the spec doc changes with it.

import SwiftUI

public extension Theme {

    /// Every theme, in display order (free first, then packs).
    static let all: [Theme] = [.showa, .gameShowClassic, .spyThriller,
                               .kremlinCartoon, .pyongyangPoster]

    static func theme(for id: ID) -> Theme {
        switch id {
        case .showa:           return .showa
        case .gameShowClassic: return .gameShowClassic
        case .spyThriller:     return .spyThriller
        case .kremlinCartoon:  return .kremlinCartoon
        case .pyongyangPoster: return .pyongyangPoster
        }
    }

    // MARK: Shōwa Broadcast (free, default)

    /// Golden-age Japanese variety show + master print shop. Paper Cream
    /// floor, Tomato Red shout, Mustard bursts, one Teal accent, warm Ink
    /// binds, Hanko Red seal.
    static let showa = Theme(
        id: .showa,
        nameKey: "SHŌWA BROADCAST",
        palette: ThemePalette(
            floor:       0xF4E9CE,   // Paper Cream
            command:     0xE23B2E,   // Tomato Red
            commandDeep: 0xC1272D,   // Hanko Red — "slightly deeper than Tomato"
            celebrate:   0xF2B417,   // Mustard Yellow
            cool:        0x1B8A8A,   // Teal (the chosen single cool; not Cobalt)
            bind:        0x1A1712,   // warm Ink
            seal:        0xC1272D,   // Hanko Red
            surface:     0xFAF3E3,   // lighter paper for readable cards
            textOnFloor: 0x1A1712,   // ink on cream
            textOnCommand: 0xFAF3E3, // cream caps on tomato plates
            positive:    0x1B8A8A,   // success wears the teal
            danger:      0xC1272D,
            meterStops:  [0x1B8A8A, 0xF2B417, 0xE23B2E]
        ),
        prefersDark: false,
        motif: .sunburstHalftone,
        sealCaption: "認証成功 · MEOW VERIFIED"
    )

    // MARK: GameShow Classic (free)

    /// The original neon look, preserved byte-exactly from the old `GameShow`
    /// literals (converted from their 0–1 component values).
    static let gameShowClassic = Theme(
        id: .gameShowClassic,
        nameKey: "GAMESHOW CLASSIC",
        palette: ThemePalette(
            floor:       0xB0218F,   // magenta (the gradient's midpoint)
            command:     0xFF3DA1,   // hot pink
            commandDeep: 0xB0218F,   // magenta
            celebrate:   0xFFEB00,   // neon yellow
            cool:        0x00E6FF,   // neon cyan
            bind:        0x170D26,   // ink black (purple-cast)
            seal:        0xFF3DA1,   // hot pink
            surface:     0xFFFAF0,   // paper white
            textOnFloor: 0xFFFAF0,   // paper white on the neon gradient
            textOnCommand: 0xFFFFFF, // the original white-on-pink
            positive:    0xA6FF33,   // neon lime
            danger:      0xFF3B30,   // matches the old `Color.red` error states
            meterStops:  [0x00E6FF, 0xA6FF33, 0xFFEB00, 0xFF3DA1]
        ),
        prefersDark: false,
        motif: .neonGradient,
        sealCaption: "MEOW VERIFIED"
    )

    // MARK: Spy Thriller — "00-Cat" (IAP)

    /// A mid-century cold open: tuxedo black, rationed champagne gold,
    /// dossier paper for anything you read, one drop of blood red.
    static let spyThriller = Theme(
        id: .spyThriller,
        nameKey: "SPY THRILLER",
        palette: ThemePalette(
            floor:       0x0E0E10,   // Tuxedo Black
            command:     0xC8A24C,   // Champagne Gold
            commandDeep: 0x9C7C38,   // darker gilt
            celebrate:   0xEDE7D6,   // Dossier Paper
            cool:        0x4A6A82,   // Steel Blue
            bind:        0x050506,   // Onyx
            seal:        0xF4F1EA,   // Gun-Barrel White
            surface:     0xEDE7D6,   // dossier cards hold all readable text
            textOnFloor: 0xEDE7D6,   // dossier paper on the night
            textOnCommand: 0x0E0E10, // night-black type on gilt
            positive:    0xC8A24C,   // success is gilt
            danger:      0xB0201C,   // Blood Red — the one drop
            meterStops:  [0x4A6A82, 0xC8A24C]
        ),
        prefersDark: true,
        motif: .reticleNight,
        sealCaption: "00-CAT · MEOW LICENCE"
    )

    // MARK: Kremlin Cartoon (IAP)

    /// Constructivist poster engine pointed at something silly. Newsprint,
    /// Poster Red doing most of the work, press black binding it.
    static let kremlinCartoon = Theme(
        id: .kremlinCartoon,
        nameKey: "KREMLIN CARTOON",
        palette: ThemePalette(
            floor:       0xEDE3CE,   // Newsprint
            command:     0xC21807,   // Poster Red
            commandDeep: 0xA8140A,   // Star Red
            celebrate:   0xD9A625,   // Machine Gold
            cool:        0x3E5A6E,   // Worker Steel
            bind:        0x161310,   // Press Black
            seal:        0xA8140A,   // Star Red
            surface:     0xF4EDDC,   // a cleaner sheet for readable panels
            textOnFloor: 0x161310,   // press black on newsprint
            textOnCommand: 0xEDE3CE, // newsprint caps on poster red
            positive:    0xD9A625,   // a gold medal for the worker
            danger:      0xA8140A,
            meterStops:  [0x3E5A6E, 0xD9A625, 0xC21807]
        ),
        prefersDark: false,
        motif: .wedgeRays,
        sealCaption: "ОДОБРЕНО · MEOW APPROVED"
    )

    // MARK: Pyongyang Poster (IAP)

    /// The festival: dawn-rose sky, radiant gold sunrise, poppy-red banners,
    /// everyone smiling. The one theme allowed a soft sky glow.
    static let pyongyangPoster = Theme(
        id: .pyongyangPoster,
        nameKey: "PYONGYANG POSTER",
        palette: ThemePalette(
            floor:       0xF6D0CE,   // Dawn Rose
            command:     0xD5203A,   // Poppy Red
            commandDeep: 0xBE1B32,   // Rosette Red
            celebrate:   0xF3B21B,   // Sunrise Gold
            cool:        0x3F86C4,   // Festival Sky
            bind:        0x211A1C,   // Poster Ink
            seal:        0xBE1B32,   // Rosette Red
            surface:     0xFBE9E1,   // sunlit paper for readable panels
            textOnFloor: 0x211A1C,   // poster ink on dawn rose
            textOnCommand: 0xFBE9E1, // sunlit caps on poppy red
            positive:    0xF3B21B,   // achievements are golden
            danger:      0xBE1B32,
            meterStops:  [0x3F86C4, 0xF3B21B, 0xD5203A]
        ),
        prefersDark: false,
        motif: .sunrise,
        sealCaption: "だいせいこう · MEOW SUCCESS"
    )
}
