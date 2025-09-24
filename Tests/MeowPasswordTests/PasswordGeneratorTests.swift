import XCTest
@testable import MeowPasswordCore

final class PasswordGeneratorTests: XCTestCase {
    private var catNameLoader: CatNameLoader!
    private var generator: PasswordGenerator!
    
    override func setUp() {
        super.setUp()
        let testNames = ["Fluffy", "Whiskers", "Shadow", "Mittens", "Tiger", "Luna", "Max", "Bella", "Charlie"]
        catNameLoader = CatNameLoader(catNames: testNames)
        generator = PasswordGenerator(catNameLoader: catNameLoader)
    }
    
    func testGenerateSecurePasswordLength() {
        let password = generator.generateSecurePassword()
        XCTAssertGreaterThanOrEqual(password.count, 15)
        XCTAssertLessThanOrEqual(password.count, 30) // Allow some buffer for insertions
    }
    
    func testGenerateSecurePasswordContainsVariousCharacterTypes() {
        let password = generator.generateSecurePassword()
        
        let hasLowercase = password.contains { $0.isLowercase }
        let hasUppercase = password.contains { $0.isUppercase }
        let hasNumbers = password.contains { $0.isNumber }
        let hasSymbols = password.contains { !$0.isLetter && !$0.isNumber }
        
        // At least some of these should be true due to our transformations
        let characterTypes = [hasLowercase, hasUppercase, hasNumbers, hasSymbols].filter { $0 }.count
        XCTAssertGreaterThan(characterTypes, 1)
    }
    
    func testGenerateSecurePasswordHasNumbers() {
        let password = generator.generateSecurePassword()
        let numberCount = password.filter { $0.isNumber }.count
        XCTAssertGreaterThanOrEqual(numberCount, 3)
        XCTAssertLessThanOrEqual(numberCount, 5)
    }
    
    func testGenerateCandidatesReturnsCorrectCount() {
        let candidates = generator.generateCandidates(count: 3)
        XCTAssertEqual(candidates.count, 3)
    }
    
    func testGenerateCandidatesHaveComplexityAnalysis() {
        let candidates = generator.generateCandidates(count: 2)
        
        for candidate in candidates {
            XCTAssertFalse(candidate.password.isEmpty)
            XCTAssertGreaterThan(candidate.complexity.score, 0)
            XCTAssertFalse(candidate.complexity.analysis.isEmpty)
        }
    }
    
    func testSelectMostSecureReturnsHighestScore() {
        // Create mock candidates with different scores
        let candidates = [
            PasswordCandidate(password: "low", complexity: KolmogorovComplexity(score: 2.0, analysis: "Low")),
            PasswordCandidate(password: "high", complexity: KolmogorovComplexity(score: 8.0, analysis: "High")),
            PasswordCandidate(password: "medium", complexity: KolmogorovComplexity(score: 5.0, analysis: "Medium"))
        ]
        
        let mostSecure = generator.selectMostSecure(from: candidates)
        XCTAssertEqual(mostSecure?.password, "high")
        XCTAssertEqual(mostSecure?.complexity.score, 8.0)
    }
    
    func testSelectMostSecureWithEmptyArray() {
        let mostSecure = generator.selectMostSecure(from: [])
        XCTAssertNil(mostSecure)
    }
    
    func testPasswordsAreUnique() {
        let passwords = (0..<10).map { _ in generator.generateSecurePassword() }
        let uniquePasswords = Set(passwords)
        
        // Most passwords should be unique (allowing for some small chance of collision)
        XCTAssertGreaterThan(uniquePasswords.count, 7)
    }
}