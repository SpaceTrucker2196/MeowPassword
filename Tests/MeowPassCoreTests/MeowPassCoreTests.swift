// Tests/MeowPassCoreTests/MeowPassCoreTests.swift

import XCTest
@testable import MeowPassCore

final class MeowPassCoreTests: XCTestCase {

    func testCatNamesLoaded() {
        let names = MeowPass.catNames()
        XCTAssertGreaterThan(names.count, 100, "Should load a substantial number of cat names")
        XCTAssertTrue(names.allSatisfy { !$0.isEmpty }, "No empty names")
    }

    func testGeneratedPasswordMeetsRequirements() {
        let config = PasswordConfig(numNumbers: 3, numSymbols: 2, maxLength: 25)
        for c in MeowPass.generate(config: config, count: 5) {
            XCTAssertGreaterThanOrEqual(c.password.count, 8)
            XCTAssertLessThanOrEqual(c.password.count, config.maxLength)
            XCTAssertTrue(c.password.contains { $0.isNumber }, "has numbers")
            XCTAssertTrue(c.password.contains { $0.isLetter }, "has letters")
            XCTAssertTrue(c.password.contains { !$0.isLetter && !$0.isNumber }, "has symbols")
            XCTAssertGreaterThanOrEqual(c.score, 0.0)
            XCTAssertLessThanOrEqual(c.score, 10.0)
        }
    }

    func testBestReturnsHighestScore() {
        let candidates = MeowPass.generate(config: PasswordConfig(), count: 5)
        let best = MeowPass.best(config: PasswordConfig(), count: 5)
        XCTAssertGreaterThanOrEqual(best.score, 0.0)
        XCTAssertFalse(candidates.isEmpty)
    }

    func testAnalyzeScoresAndVerdicts() {
        let weak = MeowPass.analyze("aaa")
        let strong = MeowPass.analyze("Xk9$mQ2!vP4@wL7#")
        XCTAssertLessThan(weak.score, strong.score)
        XCTAssertFalse(weak.verdict.isEmpty)
        XCTAssertFalse(strong.analysis.isEmpty)
    }

    func testMeowKeyIsVoiceFriendly() {
        for _ in 0..<20 {
            let key = MeowPass.meowKey(words: 3, maxLen: 5)
            let parts = key.split(separator: "-")
            XCTAssertEqual(parts.count, 3, "three words")
            for p in parts {
                XCTAssertGreaterThanOrEqual(p.count, 2)
                XCTAssertLessThanOrEqual(p.count, 5)
                XCTAssertTrue(p.allSatisfy { $0.isLetter && $0.isASCII }, "\(p) is plain ASCII letters")
            }
        }
    }
}
