// Tests/MeowUITests/ThemeTests.swift
//
// Guards the theme contract: palettes must stay byte-exact to the specs in
// docs/DESIGN.md and docs/themes/*.md, product IDs must stay byte-exact to
// the cross-platform SKU contract, and ThemeManager must persist and fall
// back correctly.

import XCTest
@testable import MeowUI

final class ThemeDefinitionTests: XCTestCase {

    func testEveryIDResolvesToAMatchingTheme() {
        for id in Theme.ID.allCases {
            XCTAssertEqual(Theme.theme(for: id).id, id)
        }
        XCTAssertEqual(Theme.all.count, Theme.ID.allCases.count)
        XCTAssertEqual(Set(Theme.all.map(\.id)), Set(Theme.ID.allCases))
    }

    // Spec tables: docs/DESIGN.md §"Color — the quota" and each theme doc's
    // "Token mapping". If one of these fails, either the code or the doc
    // changed without the other.

    func testShowaPaletteMatchesDesignDoc() {
        let p = Theme.showa.palette
        XCTAssertEqual(p.floor, 0xF4E9CE)      // Paper Cream
        XCTAssertEqual(p.command, 0xE23B2E)    // Tomato Red
        XCTAssertEqual(p.celebrate, 0xF2B417)  // Mustard Yellow
        XCTAssertEqual(p.cool, 0x1B8A8A)       // Teal
        XCTAssertEqual(p.bind, 0x1A1712)       // warm Ink
        XCTAssertEqual(p.seal, 0xC1272D)       // Hanko Red
        XCTAssertFalse(Theme.showa.prefersDark)
    }

    func testGameShowClassicPreservesTheOriginalNeonLiterals() {
        // Converted from the historical Color(red:green:blue:) literals.
        let p = Theme.gameShowClassic.palette
        XCTAssertEqual(p.command, 0xFF3DA1)    // hotPink   (1.00, 0.24, 0.63)
        XCTAssertEqual(p.commandDeep, 0xB0218F)// magenta   (0.69, 0.13, 0.56)
        XCTAssertEqual(p.celebrate, 0xFFEB00)  // neonYellow(1.00, 0.92, 0.00)
        XCTAssertEqual(p.cool, 0x00E6FF)       // neonCyan  (0.00, 0.90, 1.00)
        XCTAssertEqual(p.positive, 0xA6FF33)   // neonLime  (0.65, 1.00, 0.20)
        XCTAssertEqual(p.bind, 0x170D26)       // inkBlack  (0.09, 0.05, 0.15)
        XCTAssertEqual(p.surface, 0xFFFAF0)    // paperWhite(1.00, 0.98, 0.94)
        XCTAssertFalse(Theme.gameShowClassic.prefersDark)
    }

    func testSpyThrillerPaletteMatchesSpec() {
        let p = Theme.spyThriller.palette
        XCTAssertEqual(p.floor, 0x0E0E10)      // Tuxedo Black
        XCTAssertEqual(p.command, 0xC8A24C)    // Champagne Gold
        XCTAssertEqual(p.celebrate, 0xEDE7D6)  // Dossier Paper
        XCTAssertEqual(p.cool, 0x4A6A82)       // Steel Blue
        XCTAssertEqual(p.bind, 0x050506)       // Onyx
        XCTAssertEqual(p.seal, 0xF4F1EA)       // Gun-Barrel White
        XCTAssertEqual(p.danger, 0xB0201C)     // Blood Red
        XCTAssertTrue(Theme.spyThriller.prefersDark, "Spy is the one dark theme")
    }

    func testKremlinCartoonPaletteMatchesSpec() {
        let p = Theme.kremlinCartoon.palette
        XCTAssertEqual(p.floor, 0xEDE3CE)      // Newsprint
        XCTAssertEqual(p.command, 0xC21807)    // Poster Red
        XCTAssertEqual(p.celebrate, 0xD9A625)  // Machine Gold
        XCTAssertEqual(p.cool, 0x3E5A6E)       // Worker Steel
        XCTAssertEqual(p.bind, 0x161310)       // Press Black
        XCTAssertEqual(p.seal, 0xA8140A)       // Star Red
        XCTAssertFalse(Theme.kremlinCartoon.prefersDark)
    }

    func testPyongyangPosterPaletteMatchesSpec() {
        let p = Theme.pyongyangPoster.palette
        XCTAssertEqual(p.floor, 0xF6D0CE)      // Dawn Rose
        XCTAssertEqual(p.command, 0xD5203A)    // Poppy Red
        XCTAssertEqual(p.celebrate, 0xF3B21B)  // Sunrise Gold
        XCTAssertEqual(p.cool, 0x3F86C4)       // Festival Sky
        XCTAssertEqual(p.bind, 0x211A1C)       // Poster Ink
        XCTAssertEqual(p.seal, 0xBE1B32)       // Rosette Red
        XCTAssertFalse(Theme.pyongyangPoster.prefersDark)
    }

    func testProductIDsMatchTheCrossPlatformSKUContract() {
        // docs/themes/README.md: camelCase, never normalized.
        XCTAssertNil(Theme.ID.showa.productID)
        XCTAssertNil(Theme.ID.gameShowClassic.productID)
        XCTAssertEqual(Theme.ID.spyThriller.productID,
                       "io.river.meowPassword.spyThemePack")
        XCTAssertEqual(Theme.ID.kremlinCartoon.productID,
                       "io.river.meowPassword.kremlinThemePack")
        XCTAssertEqual(Theme.ID.pyongyangPoster.productID,
                       "io.river.meowPassword.pyongyangThemePack")
        XCTAssertEqual(Theme.ID.allCases.filter(\.isFree),
                       [.showa, .gameShowClassic])
    }

    func testEveryThemeHasMeterStopsAndASealCaption() {
        for theme in Theme.all {
            XCTAssertGreaterThanOrEqual(theme.palette.meterStops.count, 2, "\(theme.id)")
            XCTAssertFalse(theme.sealCaption.isEmpty, "\(theme.id)")
            XCTAssertFalse(theme.nameKey.isEmpty, "\(theme.id)")
        }
    }

    func testSealStylesMatchTheThemeDocs() {
        XCTAssertEqual(Theme.showa.sealStyle, .hanko)
        XCTAssertEqual(Theme.gameShowClassic.sealStyle, .hanko)
        XCTAssertEqual(Theme.spyThriller.sealStyle, .iris, "gun-barrel iris")
        XCTAssertEqual(Theme.kremlinCartoon.sealStyle, .star, "five-point star")
        XCTAssertEqual(Theme.pyongyangPoster.sealStyle, .rosette, "flower-burst rosette")
    }
}

@MainActor
final class ThemeManagerTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "ThemeManagerTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultsToTheDefaultThemeOnFirstLaunch() {
        let manager = ThemeManager(defaults: defaults)
        XCTAssertEqual(manager.selectedID, ThemeManager.defaultThemeID)
        XCTAssertTrue(manager.ownedIDs.isEmpty)
    }

    func testSelectionPersistsAcrossInstances() {
        let first = ThemeManager(defaults: defaults)
        first.selectedID = .showa
        let second = ThemeManager(defaults: defaults)
        XCTAssertEqual(second.selectedID, .showa)
    }

    func testOwnershipPersistsAcrossInstances() {
        let first = ThemeManager(defaults: defaults)
        first.setOwned([.spyThriller, .kremlinCartoon])
        let second = ThemeManager(defaults: defaults)
        XCTAssertEqual(second.ownedIDs, [.spyThriller, .kremlinCartoon])
    }

    func testUnownedPaidSelectionFallsBackToDefaultButKeepsTheChoice() {
        // A refund: selection names a pack the user no longer owns.
        let manager = ThemeManager(defaults: defaults)
        manager.selectedID = .spyThriller
        XCTAssertEqual(manager.current.id, ThemeManager.defaultThemeID,
                       "unowned pack must not render")
        XCTAssertEqual(manager.selectedID, .spyThriller,
                       "the choice survives so a repurchase restores it")
        // Repurchase: the original selection comes back on its own.
        manager.setOwned([.spyThriller])
        XCTAssertEqual(manager.current.id, .spyThriller)
    }

    func testOwnedPaidSelectionRenders() {
        let manager = ThemeManager(defaults: defaults)
        manager.setOwned([.pyongyangPoster])
        manager.selectedID = .pyongyangPoster
        XCTAssertEqual(manager.current.id, .pyongyangPoster)
    }

    func testReloadPicksUpExternalWrites() {
        // Another process (the app, while we're the extension) changes state.
        let manager = ThemeManager(defaults: defaults)
        defaults.set(Theme.ID.showa.rawValue, forKey: ThemeManager.selectedKey)
        defaults.set([Theme.ID.spyThriller.rawValue], forKey: ThemeManager.ownedKey)
        manager.reload()
        XCTAssertEqual(manager.selectedID, .showa)
        XCTAssertEqual(manager.ownedIDs, [.spyThriller])
    }

    func testGarbageStoredValuesAreIgnored() {
        defaults.set("not-a-theme", forKey: ThemeManager.selectedKey)
        defaults.set(["also-not-a-theme"], forKey: ThemeManager.ownedKey)
        let manager = ThemeManager(defaults: defaults)
        XCTAssertEqual(manager.selectedID, ThemeManager.defaultThemeID)
        XCTAssertTrue(manager.ownedIDs.isEmpty)
    }
}
