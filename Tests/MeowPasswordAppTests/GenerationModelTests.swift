import XCTest
@testable import MeowPasswordApp

/// State-management tests for the observable object that backs the UI.
/// These don't shell out to `meowpass`; they exercise defaults, guard
/// clauses, and the result-application path directly.
@MainActor
final class GenerationModelTests: XCTestCase {

    func testDefaults() {
        let model = GenerationModel()
        XCTAssertEqual(model.numbers, 3)
        XCTAssertEqual(model.symbols, 2)
        XCTAssertEqual(model.maxLength, 25)
        XCTAssertTrue(model.analyzeInput.isEmpty)
        XCTAssertTrue(model.candidates.isEmpty)
        XCTAssertTrue(model.bestPassword.isEmpty)
        XCTAssertEqual(model.bestScore, 0)
        XCTAssertTrue(model.analysisText.isEmpty)
        XCTAssertTrue(model.analyzeResult.isEmpty)
        XCTAssertFalse(model.isBusy)
        XCTAssertNil(model.lastError)
    }

    func testCopyBestNoopWhenEmpty() {
        let model = GenerationModel()
        // Empty bestPassword — the guard should skip and not mutate the pasteboard.
        model.copyBest()
        XCTAssertTrue(model.bestPassword.isEmpty)
    }

    func testAnalyzeNoopOnEmptyInput() {
        let model = GenerationModel()
        model.analyzeInput = ""
        model.analyze()
        // Should short-circuit before touching isBusy.
        XCTAssertFalse(model.isBusy)
        XCTAssertNil(model.lastError)
    }

    func testCandidateIsIdentifiable() {
        let a = GenerationModel.Candidate(password: "abc", score: 1.0)
        let b = GenerationModel.Candidate(password: "abc", score: 1.0)
        // Distinct UUIDs even for identical content.
        XCTAssertNotEqual(a.id, b.id)
    }

    func testStepperRangesRespectedWhenSetToBoundaries() {
        let model = GenerationModel()
        model.numbers = 10
        model.symbols = 10
        model.maxLength = 50
        XCTAssertEqual(model.numbers, 10)
        XCTAssertEqual(model.symbols, 10)
        XCTAssertEqual(model.maxLength, 50)
    }
}
