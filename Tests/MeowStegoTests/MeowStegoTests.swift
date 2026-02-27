// Tests/MeowStegoTests/MeowStegoTests.swift

import XCTest
@testable import MeowStego

// MARK: – PRNG

final class PRNGTests: XCTestCase {

    func testDeterminism() {
        let key: [UInt8] = [0xDE, 0xAD, 0xBE, 0xEF]
        var p1 = MeowPRNG(key: key)
        var p2 = MeowPRNG(key: key)
        let seq1 = (0..<10).map { _ in p1.nextUInt64() }
        let seq2 = (0..<10).map { _ in p2.nextUInt64() }
        XCTAssertEqual(seq1, seq2, "Same key must produce identical sequence")
    }

    func testDifferentKeysProduceDifferentOutput() {
        var p1 = MeowPRNG(key: [0x01])
        var p2 = MeowPRNG(key: [0x02])
        XCTAssertNotEqual(p1.nextUInt64(), p2.nextUInt64())
    }

    func testHexKeyInit() {
        var p1 = MeowPRNG(key: [0xDE, 0xAD])
        var p2 = MeowPRNG(hexKey: "dead")!
        XCTAssertEqual(p1.nextUInt64(), p2.nextUInt64())
    }

    func testInvalidHexKeyReturnsNil() {
        XCTAssertNil(MeowPRNG(hexKey: "xyz"))
        XCTAssertNil(MeowPRNG(hexKey: "abc"))   // odd length
    }

    func testPermutationIsCorrect() {
        var prng = MeowPRNG(key: [1, 2, 3])
        let perm = prng.shuffled(100)

        XCTAssertEqual(perm.count, 100)
        XCTAssertEqual(Set(perm).count, 100, "No duplicates")
        XCTAssertEqual(Set(perm), Set(0..<100), "Covers 0..<100")
    }

    func testPermutationIsDeterministic() {
        var p1 = MeowPRNG(key: [1, 2, 3])
        var p2 = MeowPRNG(key: [1, 2, 3])
        XCTAssertEqual(p1.shuffled(100), p2.shuffled(100))
    }
}

// MARK: – GF256

final class GF256Tests: XCTestCase {

    func testMultiplicativeIdentity() {
        let x: UInt8 = 0xA3
        XCTAssertEqual(GF256.mul(x, 1), x)
    }

    func testMultiplyByZero() {
        XCTAssertEqual(GF256.mul(0xA3, 0), 0)
        XCTAssertEqual(GF256.mul(0, 0xA3), 0)
    }

    func testCommutativity() {
        let a: UInt8 = 0xA3
        let b: UInt8 = 0x7F
        XCTAssertEqual(GF256.mul(a, b), GF256.mul(b, a))
    }

    func testMultiplicativeInverse() {
        let x: UInt8 = 0xA3
        XCTAssertEqual(GF256.mul(x, GF256.inv(x)), 1)
    }

    func testDistributivity() {
        // a*(b XOR c) = a*b XOR a*c
        let a: UInt8 = 0xA3, b: UInt8 = 0x7F, c: UInt8 = 0x13
        XCTAssertEqual(GF256.mul(a, b ^ c), GF256.mul(a, b) ^ GF256.mul(a, c))
    }
}

// MARK: – Reed-Solomon

final class ReedSolomonTests: XCTestCase {

    func testEncodeDecodeLengths() {
        let rs = ReedSolomon(nsym: 32)
        let msg: [UInt8] = Array("Hello, MeowPassword!".utf8)
        let encoded = rs.encode(msg)
        XCTAssertEqual(encoded.count, msg.count + 32)
    }

    func testCleanRoundTrip() {
        let rs = ReedSolomon(nsym: 32)
        let msg: [UInt8] = Array("Hello, MeowPassword!".utf8)
        let encoded = rs.encode(msg)
        XCTAssertEqual(rs.decode(encoded), msg)
    }

    func testSingleSymbolErrorCorrection() {
        let rs = ReedSolomon(nsym: 32)
        let msg: [UInt8] = Array(repeating: 0xAB, count: 40)
        var encoded = rs.encode(msg)
        encoded[10] ^= 0xFF
        XCTAssertEqual(rs.decode(encoded), msg)
    }

    func testMaxErrorCorrection() {
        let rs = ReedSolomon(nsym: 32)
        let msg: [UInt8] = Array(0..<40 as Range<UInt8>)
        var encoded = rs.encode(msg)
        // Corrupt exactly t = nsym/2 = 16 symbols.
        for i in 0..<16 { encoded[i] ^= 0xFF }
        XCTAssertEqual(rs.decode(encoded), msg,
                       "Must correct exactly t=16 symbol errors")
    }

    func testUncorrectableReturnsNil() {
        let rs = ReedSolomon(nsym: 4)
        let msg: [UInt8] = [1, 2, 3, 4, 5]
        var encoded = rs.encode(msg)
        // 3 errors exceeds t = 2.
        encoded[0] ^= 0xFF
        encoded[1] ^= 0xFF
        encoded[2] ^= 0xFF
        XCTAssertNil(rs.decode(encoded))
    }
}

// MARK: – QIM

final class QIMTests: XCTestCase {

    func testRoundTrip() {
        let step: Float = 32.0
        for c: Float in [-100, -50, 0, 50, 100, 150] {
            let emb0 = qimEmbed(c, bit: 0, step: step)
            let emb1 = qimEmbed(c, bit: 1, step: step)
            XCTAssertEqual(qimExtract(emb0, step: step), 0,
                           "bit=0 round-trip from \(c)")
            XCTAssertEqual(qimExtract(emb1, step: step), 1,
                           "bit=1 round-trip from \(c)")
        }
    }

    func testRobustnessToSmallPerturbation() {
        let step: Float = 32.0
        // Noise < step/4 must not flip the extracted bit.
        let c: Float = 37.5
        let noise: Float = step / 4 - 1.0
        for bit in [0, 1] {
            let emb = qimEmbed(c, bit: bit, step: step)
            XCTAssertEqual(qimExtract(emb + noise, step: step), bit,
                           "Survives +noise for bit=\(bit)")
            XCTAssertEqual(qimExtract(emb - noise, step: step), bit,
                           "Survives −noise for bit=\(bit)")
        }
    }
}

// MARK: – DCT

final class DCTTests: XCTestCase {

    func testRoundTrip() {
        let block = [Float](repeating: 50.0, count: 64)
        let coeffs = DCT8x8Provider.dct(block)
        let reconstructed = DCT8x8Provider.idct(coeffs)
        let maxErr = zip(block, reconstructed).map { abs($0 - $1) }.max()!
        XCTAssertLessThan(maxErr, 0.5, "DCT round-trip error must be < 0.5 LSB")
    }

    func testZigZagCount() {
        XCTAssertEqual(DCT8x8Provider.zigZagOrder.count, 64)
        XCTAssertEqual(DCT8x8Provider.zigZagOrder[0].0, 0)
        XCTAssertEqual(DCT8x8Provider.zigZagOrder[0].1, 0)
        XCTAssertEqual(DCT8x8Provider.midBandPositions.count, 10)
    }
}

// MARK: – End-to-end steganography

final class StegoEndToEndTests: XCTestCase {

    private let key: [UInt8] = [0xCA, 0xFE, 0xBA, 0xBE]
    private let W = 256, H = 256

    func testEncodeDecodeRoundTrip() throws {
        let payload = Array("MeowStego secret payload 🐱".utf8)
        var pixels = [UInt8](repeating: 128, count: W * H)

        let encoder = StegoEncoder(wmKey: key, qimStep: 32.0)
        let decoder = StegoDecoder(wmKey: key, qimStep: 32.0)

        try encoder.encode(payload: payload, into: &pixels, width: W, height: H)
        let recovered = try decoder.decode(from: pixels, width: W, height: H)
        XCTAssertEqual(recovered, payload)
    }

    func testWrongKeyThrowsError() throws {
        let payload: [UInt8] = Array("secret".utf8)
        var pixels = [UInt8](repeating: 128, count: W * H)

        let encoder = StegoEncoder(wmKey: key)
        let decoder = StegoDecoder(wmKey: [0xFF, 0xFE])

        try encoder.encode(payload: payload, into: &pixels, width: W, height: H)
        XCTAssertThrowsError(
            try decoder.decode(from: pixels, width: W, height: H)
        )
    }

    func testPayloadTooLargeThrows() {
        let largePayload = [UInt8](repeating: 0, count: 513)
        var pixels = [UInt8](repeating: 128, count: W * H)
        let encoder = StegoEncoder(wmKey: key)
        XCTAssertThrowsError(
            try encoder.encode(payload: largePayload, into: &pixels, width: W, height: H)
        )
    }

    func testInsufficientCapacityThrows() {
        let payload = [UInt8](repeating: 0xFF, count: 512)
        var pixels = [UInt8](repeating: 128, count: 64 * 64)
        let encoder = StegoEncoder(wmKey: key)
        XCTAssertThrowsError(
            try encoder.encode(payload: payload, into: &pixels, width: 64, height: 64)
        )
    }

    func testInvalidDimensionsThrows() {
        var pixels = [UInt8](repeating: 128, count: 100 * 100)
        let encoder = StegoEncoder(wmKey: key)
        XCTAssertThrowsError(
            try encoder.encode(payload: [1, 2, 3], into: &pixels, width: 100, height: 100)
        )
    }

    func testLargePayloadRoundTrip() throws {
        // 512-byte payload in a 512×512 image.
        let payload = (0..<512).map { UInt8($0 & 0xFF) }
        let bigW = 512, bigH = 512
        var pixels = [UInt8](repeating: 128, count: bigW * bigH)

        let encoder = StegoEncoder(wmKey: key, qimStep: 32.0)
        let decoder = StegoDecoder(wmKey: key, qimStep: 32.0)

        try encoder.encode(payload: payload, into: &pixels, width: bigW, height: bigH)
        let recovered = try decoder.decode(from: pixels, width: bigW, height: bigH)
        XCTAssertEqual(recovered, payload)
    }
}
