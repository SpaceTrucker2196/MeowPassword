import XCTest
@testable import MeowPassword

/// Drives the real iOS view-model through the compose → decode flow to prove
/// both work end to end on iOS (embed into a bundled cat, then decode the
/// produced PNG back to the original message).
@MainActor
final class MeowGramFlowTests: XCTestCase {

    // DCT embed/decode is slow in a Debug simulator build (the same math takes
    // ~30s per op on macOS Debug), so allow a generous window.
    private func waitUntil(_ cond: @escaping () -> Bool,
                           timeout: TimeInterval = 180,
                           _ message: String = "condition not met") async throws {
        let start = Date()
        while !cond() {
            if Date().timeIntervalSince(start) > timeout { XCTFail("Timed out: \(message)"); return }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    func testCatalogLoads() {
        let model = MeowGramModeliOS()
        model.load()
        XCTAssertEqual(model.catalog.count, 100, "all 100 keyed cats should bundle on iOS")
    }

    func testComposeThenDecodeRoundTrip() async throws {
        let composer = MeowGramModeliOS()
        composer.load()
        composer.selectedID = composer.catalog.first?.id
        composer.message = "meet at the sunny windowsill at 3pm 🐾"
        composer.embed()
        try await waitUntil({ composer.encodedPNG != nil || composer.errorText != nil }, "embed")
        XCTAssertNil(composer.errorText, "compose should succeed")
        let png = try XCTUnwrap(composer.encodedPNG, "compose should produce a PNG")

        let decoder = MeowGramModeliOS()
        decoder.decode(data: png, display: nil)
        try await waitUntil({ decoder.decodedMessage != nil || decoder.errorText != nil }, "decode")
        XCTAssertEqual(decoder.decodedMessage, "meet at the sunny windowsill at 3pm 🐾")
        XCTAssertNotNil(decoder.decodedGUID, "an authentic MeowGram carries a provenance GUID")
    }

    func testPassphraseRoundTrip() async throws {
        let composer = MeowGramModeliOS()
        composer.load()
        composer.selectedID = composer.catalog.first?.id
        composer.message = "locked kitty secret"
        composer.passphrase = "tuna"
        composer.embed()
        try await waitUntil({ composer.encodedPNG != nil || composer.errorText != nil }, "embed+lock")
        let png = try XCTUnwrap(composer.encodedPNG)

        // Wrong (empty) passphrase should fail to reveal the message.
        let wrong = MeowGramModeliOS()
        wrong.decode(data: png, display: nil)
        try await waitUntil({ wrong.decodedMessage != nil || wrong.errorText != nil }, "decode-no-pass")
        XCTAssertNil(wrong.decodedMessage, "locked message must not decode without the passphrase")
        XCTAssertNotNil(wrong.errorText)

        // Correct passphrase reveals it.
        let right = MeowGramModeliOS()
        right.passphrase = "tuna"
        right.decode(data: png, display: nil)
        try await waitUntil({ right.decodedMessage != nil || right.errorText != nil }, "decode-pass")
        XCTAssertEqual(right.decodedMessage, "locked kitty secret")
    }
}
