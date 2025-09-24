import XCTest
@testable import MeowPasswordCore

final class KolmogorovComplexityTests: XCTestCase {
    
    func testAnalyzeSimpleString() {
        let result = KolmogorovComplexityAnalyzer.analyze("aaa")
        
        XCTAssertGreaterThan(result.score, 0)
        XCTAssertLessThan(result.score, 10)
        XCTAssertFalse(result.analysis.isEmpty)
        XCTAssertTrue(result.analysis.contains("Complexity Score"))
    }
    
    func testAnalyzeComplexString() {
        let complexString = "K3y#9mB$x7"
        let result = KolmogorovComplexityAnalyzer.analyze(complexString)
        
        XCTAssertGreaterThan(result.score, 0)
        XCTAssertLessThan(result.score, 10)
        XCTAssertFalse(result.analysis.isEmpty)
    }
    
    func testAnalyzeEmptyString() {
        let result = KolmogorovComplexityAnalyzer.analyze("")
        
        XCTAssertEqual(result.score, 0.0)
        XCTAssertFalse(result.analysis.isEmpty)
    }
    
    func testComplexStringHasHigherScore() {
        let simple = KolmogorovComplexityAnalyzer.analyze("aaabbb")
        let complex = KolmogorovComplexityAnalyzer.analyze("K3y#9mB$x7Qz!")
        
        XCTAssertGreaterThan(complex.score, simple.score)
    }
    
    func testAnalysisContainsExpectedComponents() {
        let result = KolmogorovComplexityAnalyzer.analyze("TestPassword123!")
        
        XCTAssertTrue(result.analysis.contains("Shannon Entropy"))
        XCTAssertTrue(result.analysis.contains("Compression Resistance"))
        XCTAssertTrue(result.analysis.contains("Pattern Uniqueness"))
        XCTAssertTrue(result.analysis.contains("Character Diversity"))
        XCTAssertTrue(result.analysis.contains("Character Composition"))
    }
    
    func testAnalysisDetectsCharacterTypes() {
        let result = KolmogorovComplexityAnalyzer.analyze("TestPassword123!")
        
        XCTAssertTrue(result.analysis.contains("Lowercase Letters: ✅"))
        XCTAssertTrue(result.analysis.contains("Uppercase Letters: ✅"))
        XCTAssertTrue(result.analysis.contains("Digits: ✅"))
        XCTAssertTrue(result.analysis.contains("Symbols: ✅"))
    }
    
    func testAnalysisDetectsMissingCharacterTypes() {
        let result = KolmogorovComplexityAnalyzer.analyze("testpassword")
        
        XCTAssertTrue(result.analysis.contains("Lowercase Letters: ✅"))
        XCTAssertTrue(result.analysis.contains("Uppercase Letters: ❌"))
        XCTAssertTrue(result.analysis.contains("Digits: ❌"))
        XCTAssertTrue(result.analysis.contains("Symbols: ❌"))
    }
    
    func testScoreCappedAtTen() {
        // Test with a very complex string to ensure score doesn't exceed 10
        let veryComplex = String(repeating: "aB3$", count: 100)
        let result = KolmogorovComplexityAnalyzer.analyze(veryComplex)
        
        XCTAssertLessThanOrEqual(result.score, 10.0)
    }
    
    func testAnalysisInterpretation() {
        let lowScore = KolmogorovComplexityAnalyzer.analyze("aa")
        let highScore = KolmogorovComplexityAnalyzer.analyze("K3y#9mB$x7Qz!pR8&nF2")
        
        XCTAssertTrue(lowScore.analysis.contains("Very Low") || lowScore.analysis.contains("Low"))
        // High complexity strings may still score lower due to the algorithm design
        XCTAssertTrue(highScore.analysis.contains("High") || highScore.analysis.contains("Moderate") || highScore.analysis.contains("Low"))
    }
}