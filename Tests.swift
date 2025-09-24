//
//  Tests.swift
//  MeowPassword Tests
//
//  Unit and Integration Tests for MeowPassword
//

import Foundation

// MARK: - Test Helper Functions
func assert(_ condition: Bool, _ message: String) {
    if condition {
        print("✅ PASS: \(message)")
    } else {
        print("❌ FAIL: \(message)")
    }
}

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    if actual == expected {
        print("✅ PASS: \(message)")
    } else {
        print("❌ FAIL: \(message) - Expected: \(expected), Got: \(actual)")
    }
}

// MARK: - Cat Name Loading Tests
func testLoadCatNames() {
    print("\n🧪 Testing Cat Name Loading...")
    
    // Test loading from existing file
    let catNames = loadCatNames(from: "catNamesText.txt")
    assert(!catNames.isEmpty, "Should load cat names from catNamesText.txt")
    assert(catNames.count > 1000, "Should load a substantial number of cat names")
    
    // Test that loaded names are not empty strings
    let nonEmptyNames = catNames.filter { !$0.isEmpty }
    assertEqual(nonEmptyNames.count, catNames.count, "All loaded names should be non-empty")
    
    // Test loading from non-existent file
    let emptyNames = loadCatNames(from: "nonexistent.txt")
    assertEqual(emptyNames.count, 0, "Should return empty array for non-existent file")
    
    print("Cat names loaded: \(catNames.count)")
    print("First few names: \(Array(catNames.prefix(5)))")
}

// MARK: - Random Selection Tests
func testSelectRandomCatNames() {
    print("\n🧪 Testing Random Cat Name Selection...")
    
    let testNames = ["Fluffy", "Whiskers", "Shadow", "Mittens", "Tiger"]
    
    // Test normal selection
    let selected3 = selectRandomCatNames(from: testNames, count: 3)
    assertEqual(selected3.count, 3, "Should select exactly 3 names")
    
    // Test selection with count larger than available
    let selectedAll = selectRandomCatNames(from: testNames, count: 10)
    assertEqual(selectedAll.count, 5, "Should select all available names when count exceeds available")
    
    // Test with empty array
    let selectedEmpty = selectRandomCatNames(from: [], count: 3)
    assertEqual(selectedEmpty.count, 0, "Should return empty array when input is empty")
    
    // Test with zero count
    let selectedZero = selectRandomCatNames(from: testNames, count: 0)
    assertEqual(selectedZero.count, 0, "Should return empty array when count is 0")
}

// MARK: - Base Phrase Creation Tests
func testCreateBasePhrase() {
    print("\n🧪 Testing Base Phrase Creation...")
    
    let shortNames = ["Cat", "Dog"]
    let phrase1 = createBasePhrase(from: shortNames)
    assert(phrase1.count >= 6, "Should contain the joined names")
    
    let longNames = ["VeryLongCatNameThatExceedsLimit", "AnotherLongName"]
    let phrase2 = createBasePhrase(from: longNames)
    assert(phrase2.count <= 25, "Should truncate to 25 characters maximum")
    
    let normalNames = ["Fluffy", "Whiskers", "Shadow"]
    let phrase3 = createBasePhrase(from: normalNames)
    assert(phrase3.count >= 15 && phrase3.count <= 25, "Should be between 15-25 characters")
}

// MARK: - Password Transformation Tests
func testRandomlyCapitalizeLetters() {
    print("\n🧪 Testing Random Capitalization...")
    
    var password = Array("fluffywhiskers")
    randomlyCapitalizeLetters(in: &password, count: 3)
    
    let uppercaseCount = password.filter { $0.isUppercase }.count
    assertEqual(uppercaseCount, 3, "Should capitalize exactly 3 letters")
    
    let originalLength = "fluffywhiskers".count
    assertEqual(password.count, originalLength, "Should not change password length")
}

func testInsertRandomNumbers() {
    print("\n🧪 Testing Number Insertion...")
    
    var password = Array("fluffy")
    let originalLength = password.count
    insertRandomNumbers(into: &password, count: 4)
    
    assertEqual(password.count, originalLength + 4, "Should add exactly 4 characters")
    
    let numberCount = password.filter { $0.isNumber }.count
    assertEqual(numberCount, 4, "Should insert exactly 4 numbers")
}

func testReplaceLettersWithSymbols() {
    print("\n🧪 Testing Symbol Replacement...")
    
    var password = Array("fluffywhiskers")
    let originalLength = password.count
    replaceLettersWithSymbols(in: &password, count: 2)
    
    assertEqual(password.count, originalLength, "Should not change password length")
    
    let symbolCount = password.filter { !$0.isLetter && !$0.isNumber }.count
    assertEqual(symbolCount, 2, "Should have exactly 2 symbols")
}

func testRemoveRepeatingLetters() {
    print("\n🧪 Testing Repeating Letter Removal...")
    
    var password = Array("fluffffy")
    removeRepeatingLetters(in: &password)
    
    let letterCounts = password.reduce(into: [Character: Int]()) { counts, char in
        if char.isLetter {
            let lowerChar = Character(char.lowercased())
            counts[lowerChar, default: 0] += 1
        }
    }
    
    // Check that no letter appears more than once
    let maxCount = letterCounts.values.max() ?? 0
    assert(maxCount <= 1, "Should not have any repeating letters")
}

// MARK: - Complexity Analysis Tests
func testShannonEntropy() {
    print("\n🧪 Testing Shannon Entropy Calculation...")
    
    let simpleString = "aaa"
    let entropy1 = calculateShannonEntropy(of: simpleString)
    assert(entropy1 == 0.0, "Entropy of identical characters should be 0")
    
    let complexString = "abcdefg"
    let entropy2 = calculateShannonEntropy(of: complexString)
    assert(entropy2 > entropy1, "More diverse string should have higher entropy")
}

func testCompressionRatio() {
    print("\n🧪 Testing Compression Ratio...")
    
    let repetitive = "aaabbbccc"
    let ratio1 = calculateCompressionRatio(of: repetitive)
    
    let diverse = "abcdefghi"
    let ratio2 = calculateCompressionRatio(of: diverse)
    
    assert(ratio1 >= 0.0 && ratio1 <= 1.0, "Compression ratio should be between 0 and 1")
    assert(ratio2 >= 0.0 && ratio2 <= 1.0, "Compression ratio should be between 0 and 1")
}

func testPatternComplexity() {
    print("\n🧪 Testing Pattern Complexity...")
    
    let simple = "abcabc"
    let complexity1 = calculatePatternComplexity(of: simple)
    
    let complex = "abcdefghijk"
    let complexity2 = calculatePatternComplexity(of: complex)
    
    assert(complexity1 >= 0.0 && complexity1 <= 1.0, "Pattern complexity should be between 0 and 1")
    assert(complexity2 >= 0.0 && complexity2 <= 1.0, "Pattern complexity should be between 0 and 1")
}

func testCharacterDiversity() {
    print("\n🧪 Testing Character Diversity...")
    
    let onlyLower = "abcdef"
    let diversity1 = calculateCharacterDiversity(of: onlyLower)
    assertEqual(diversity1, 0.25, "Only lowercase should give 0.25 diversity")
    
    let mixed = "AbC123!@"
    let diversity2 = calculateCharacterDiversity(of: mixed)
    assertEqual(diversity2, 1.0, "All character types should give 1.0 diversity")
}

func testAnalyzeComplexity() {
    print("\n🧪 Testing Complete Complexity Analysis...")
    
    let password = "FlUfFy123!@"
    let (score, analysis) = analyzeComplexity(of: password)
    
    assert(score >= 0.0 && score <= 10.0, "Complexity score should be between 0 and 10")
    assert(analysis.contains("Kolmogorov Complexity Analysis"), "Analysis should contain expected content")
    assert(analysis.contains(password), "Analysis should contain the password")
}

// MARK: - Integration Tests
func testCompletePasswordGeneration() {
    print("\n🧪 Testing Complete Password Generation...")
    
    let testNames = ["Fluffy", "Whiskers", "Shadow", "Mittens", "Tiger", "Luna", "Max", "Bella"]
    
    for i in 1...5 {
        let password = generateSecurePassword(from: testNames)
        
        print("Generated password \(i): \(password)")
        
        // Test length requirements
        assert(password.count >= 10, "Password should be at least 10 characters (allowing for transformations)")
        assert(password.count <= 35, "Password should not exceed 35 characters")
        
        // Test character variety
        let hasNumbers = password.contains { $0.isNumber }
        let hasLetters = password.contains { $0.isLetter }
        let hasSymbols = password.contains { !$0.isLetter && !$0.isNumber }
        
        assert(hasNumbers, "Password should contain numbers")
        assert(hasLetters, "Password should contain letters")
        assert(hasSymbols, "Password should contain symbols")
        
        // Test complexity analysis
        let (score, analysis) = analyzeComplexity(of: password)
        assert(score >= 0.0 && score <= 10.0, "Complexity score should be valid")
        assert(!analysis.isEmpty, "Analysis should not be empty")
    }
}

func testPasswordUniqueness() {
    print("\n🧪 Testing Password Uniqueness...")
    
    let testNames = ["Fluffy", "Whiskers", "Shadow", "Mittens", "Tiger", "Luna", "Max", "Bella"]
    var passwords: Set<String> = []
    
    for _ in 1...10 {
        let password = generateSecurePassword(from: testNames)
        passwords.insert(password)
    }
    
    assert(passwords.count >= 8, "Should generate mostly unique passwords")
}

// MARK: - Test Runner
func runAllTests() {
    print("🚀 Starting MeowPassword Test Suite")
    print("====================================")
    
    testLoadCatNames()
    testSelectRandomCatNames()
    testCreateBasePhrase()
    testRandomlyCapitalizeLetters()
    testInsertRandomNumbers()
    testReplaceLettersWithSymbols()
    testRemoveRepeatingLetters()
    testShannonEntropy()
    testCompressionRatio()
    testPatternComplexity()
    testCharacterDiversity()
    testAnalyzeComplexity()
    testCompletePasswordGeneration()
    testPasswordUniqueness()
    
    print("\n🎉 Test Suite Complete!")
    print("====================================")
}

// Run tests if this is the main execution
if CommandLine.arguments.contains("--test") {
    runAllTests()
}