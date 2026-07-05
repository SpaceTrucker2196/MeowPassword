// Tests/MeowStegoTests/StegoBandTests.swift

import XCTest
@testable import MeowStego

/// Builds a deterministic, textured luma image with values spanning the full
/// 0–255 range (including saturated regions) so cross-talk tests exercise the
/// pixel-clamping tail, not just a flat mid-gray.
private func texturedImage(width: Int, height: Int, seed: [UInt8]) -> [UInt8] {
    var prng = MeowPRNG(key: seed)
    var pixels = [UInt8](repeating: 0, count: width * height)
    for r in 0..<height {
        for c in 0..<width {
            let gradient = (r + c) * 255 / (width + height)      // 0…255 ramp
            let noise = Int(prng.nextUInt64() % 40) - 20          // ±20
            pixels[r * width + c] = UInt8(max(0, min(255, gradient + noise)))
        }
    }
    return pixels
}

final class StegoBandTests: XCTestCase {

    // Real shipping geometry.
    private let W = 544, H = 680
    private let keyKey: [UInt8]  = [0x4d, 0x65, 0x6f, 0x77, 0x01]
    private let msgKey: [UInt8]  = [0x9a, 0x3f, 0xe1, 0x07, 0x02]

    func testFullBandMatchesLegacyMidBand() {
        XCTAssertEqual(StegoBand.full.zigZagRange, 10..<20)
        let full = StegoBand.full.positions.map { [$0.0, $0.1] }
        let legacy = DCT8x8Provider.midBandPositions.map { [$0.0, $0.1] }
        XCTAssertEqual(full, legacy, "`.full` must reproduce the historical mid-band positions")
    }

    func testKeyAndMessageBandsAreDisjoint() {
        XCTAssertTrue(StegoBand.key.isDisjoint(from: .message))
        XCTAssertTrue(StegoBand.message.isDisjoint(from: .key))
    }

    /// The load-bearing claim: a GUID in the key band survives a user embedding
    /// — and re-embedding — a max-size message in the disjoint message band.
    func testProvenanceKeySurvivesMessageEmbedAndReEmbed() throws {
        var img = texturedImage(width: W, height: H, seed: [1, 2, 3, 4])

        let guid = (0..<16).map { UInt8(($0 * 37 + 11) & 0xFF) }
        try StegoEncoder(wmKey: keyKey, qimStep: 48, band: .key)
            .encode(payload: guid, into: &img, width: W, height: H)

        // First message.
        let msg1 = (0..<400).map { UInt8(($0 * 3 + 1) & 0xFF) }
        try StegoEncoder(wmKey: msgKey, qimStep: 32, band: .message)
            .encode(payload: msg1, into: &img, width: W, height: H)

        // Re-embed (overwrite) with a different message — the user edits and re-sends.
        let msg2 = (0..<400).map { UInt8(($0 * 7 + 5) & 0xFF) }
        try StegoEncoder(wmKey: msgKey, qimStep: 32, band: .message)
            .encode(payload: msg2, into: &img, width: W, height: H)

        // The GUID must still decode cleanly.
        let recoveredGUID = try StegoDecoder(wmKey: keyKey, qimStep: 48, band: .key)
            .decode(from: img, width: W, height: H)
        XCTAssertEqual(recoveredGUID, guid, "Provenance key must survive message re-embed")

        // And the latest message must decode.
        let recoveredMsg = try StegoDecoder(wmKey: msgKey, qimStep: 32, band: .message)
            .decode(from: img, width: W, height: H)
        XCTAssertEqual(recoveredMsg, msg2, "Latest message must decode after re-embed")
    }

    func testMessageBandDoesNotLeakIntoKeyDecodeWithWrongKey() throws {
        var img = texturedImage(width: W, height: H, seed: [9, 9, 9])
        let guid = (0..<16).map { UInt8($0) }
        try StegoEncoder(wmKey: keyKey, qimStep: 48, band: .key)
            .encode(payload: guid, into: &img, width: W, height: H)
        // A decoder with the wrong key / band should not spuriously find the GUID.
        XCTAssertThrowsError(
            try StegoDecoder(wmKey: [0xFF], qimStep: 48, band: .key)
                .decode(from: img, width: W, height: H)
        )
    }
}

final class YCbCrTests: XCTestCase {

    func testRGBRoundTripFidelity() {
        // Random-ish RGB; round-tripping unmodified luma must stay within a
        // gray level or two of the original (BT.601 + byte quantization).
        var prng = MeowPRNG(key: [7, 7, 7])
        let n = 5000
        var rgb = [UInt8](repeating: 0, count: n * 3)
        for i in 0..<(n * 3) { rgb[i] = UInt8(prng.nextUInt64() % 256) }

        let (y, cb, cr) = YCbCr.fromRGB(rgb: rgb, pixelCount: n)
        let back = YCbCr.toRGB(y: y, cb: cb, cr: cr)

        var maxErr = 0
        for i in 0..<(n * 3) {
            maxErr = max(maxErr, abs(Int(rgb[i]) - Int(back[i])))
        }
        XCTAssertLessThanOrEqual(maxErr, 2, "RGB→YCbCr→RGB round-trip should be near-lossless")
    }
}
