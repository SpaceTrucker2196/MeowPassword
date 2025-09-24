import XCTest
@testable import MeowPasswordCore

final class IntegrationTests: XCTestCase {
    
    func testCompletePasswordGenerationWorkflow() throws {
        // Create a temporary cat names file
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("integration_test_cats.txt")
        
        let catNames = """
        Fluffy
        Whiskers
        Shadow
        Mittens
        Tiger
        Luna
        Max
        Bella
        Charlie
        Oliver
        Smokey
        Patches
        Ginger
        Oreo
        Felix
        """
        
        try catNames.write(to: tempFile, atomically: true, encoding: .utf8)
        
        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        // Test the complete workflow
        guard let catNameLoader = CatNameLoader(from: tempFile.path) else {
            XCTFail("Failed to load cat names from temporary file")
            return
        }
        
        let generator = PasswordGenerator(catNameLoader: catNameLoader)
        
        // Generate candidates
        let candidates = generator.generateCandidates(count: 5)
        
        // Verify we have 5 candidates
        XCTAssertEqual(candidates.count, 5)
        
        // Verify each candidate meets basic requirements
        for candidate in candidates {
            // Check password length (allowing some buffer for transformations)
            XCTAssertGreaterThanOrEqual(candidate.password.count, 10, "Password too short: \(candidate.password)")
            XCTAssertLessThanOrEqual(candidate.password.count, 35, "Password too long: \(candidate.password)")
            
            // Check complexity score is valid
            XCTAssertGreaterThanOrEqual(candidate.complexity.score, 0)
            XCTAssertLessThanOrEqual(candidate.complexity.score, 10)
            
            // Check analysis is present
            XCTAssertFalse(candidate.complexity.analysis.isEmpty)
            XCTAssertTrue(candidate.complexity.analysis.contains("Complexity Score"))
        }
        
        // Select most secure
        guard let mostSecure = generator.selectMostSecure(from: candidates) else {
            XCTFail("Failed to select most secure password")
            return
        }
        
        // Verify the most secure password has the highest score
        let maxScore = candidates.map { $0.complexity.score }.max()
        XCTAssertEqual(mostSecure.complexity.score, maxScore)
        
        // Verify password security requirements
        let password = mostSecure.password
        
        // Should have variety of character types (due to transformations)
        let hasNumbers = password.contains { $0.isNumber }
        let hasLetters = password.contains { $0.isLetter }
        
        XCTAssertTrue(hasNumbers, "Password should contain numbers")
        XCTAssertTrue(hasLetters, "Password should contain letters")
        
        print("✅ Integration test passed!")
        print("🔐 Generated password: \(password)")
        print("📊 Complexity score: \(mostSecure.complexity.score)")
    }
    
    func testPasswordSecurityRequirements() {
        let testNames = ["Fluffy", "Whiskers", "Shadow", "Mittens", "Tiger", "Luna", "Max", "Bella", "Charlie", "Oliver"]
        let catNameLoader = CatNameLoader(catNames: testNames)
        let generator = PasswordGenerator(catNameLoader: catNameLoader)
        
        // Generate multiple passwords to test requirements statistically
        for _ in 0..<10 {
            let password = generator.generateSecurePassword()
            
            // Count character types
            let numbers = password.filter { $0.isNumber }
            let letters = password.filter { $0.isLetter }
            let symbols = password.filter { !$0.isLetter && !$0.isNumber }
            
            // Should have numbers (3-5 inserted)
            XCTAssertGreaterThanOrEqual(numbers.count, 1, "Password should have numbers: \(password)")
            
            // Should have letters (from cat names)
            XCTAssertGreaterThanOrEqual(letters.count, 5, "Password should have letters: \(password)")
            
            // Should have some uppercase (3 random capitalizations)
            let uppercaseCount = password.filter { $0.isUppercase }.count
            XCTAssertGreaterThanOrEqual(uppercaseCount, 1, "Password should have uppercase: \(password)")
            
            // Should have symbols (2 replacements)
            XCTAssertGreaterThanOrEqual(symbols.count, 1, "Password should have symbols: \(password)")
        }
    }
    
    func testKolmogorovAnalysisRealistic() {
        // Test with realistic password-like strings
        let testStrings = [
            "FluffyWhiskersMax123!@",
            "a1b2c3d4e5",
            "ComplexP@ssw0rd!",
            "aaaaaaaaaa",
            "RandomCatNamesWithSymbols#9$"
        ]
        
        for testString in testStrings {
            let analysis = KolmogorovComplexityAnalyzer.analyze(testString)
            
            XCTAssertGreaterThan(analysis.score, 0)
            XCTAssertLessThanOrEqual(analysis.score, 10)
            XCTAssertFalse(analysis.analysis.isEmpty)
            
            // Should contain key analysis components
            XCTAssertTrue(analysis.analysis.contains("Shannon Entropy"))
            XCTAssertTrue(analysis.analysis.contains("Character Diversity"))
            
            print("String: \(testString)")
            print("Score: \(analysis.score)")
            print("---")
        }
    }
}