//
//  main.swift
//  MeowPassword
//
//  Created by Jeffrey Kunzelman on 8/23/25.
//

import Foundation

// MARK: - Cat Name Loading
func loadCatNames(from filePath: String) -> [String] {
    guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else {
        print("Error: Could not load cat names from \(filePath)")
        return []
    }
    
    return content.components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
}

// MARK: - Random Cat Name Selection
func selectRandomCatNames(from catNames: [String], count: Int) -> [String] {
    guard !catNames.isEmpty, count > 0 else { return [] }
    
    let actualCount = min(count, catNames.count)
    return Array(catNames.shuffled().prefix(actualCount))
}

// MARK: - Base Phrase Creation
func createBasePhrase(from catNames: [String]) -> String {
    let joinedNames = catNames.joined()
    
    // Ensure phrase is between 15-25 characters
    if joinedNames.count < 15 {
        // If too short, try adding more names
        let additionalNames = selectRandomCatNames(from: catNames, count: 2)
        let extended = joinedNames + additionalNames.joined()
        return String(extended.prefix(25))
    } else if joinedNames.count > 25 {
        return String(joinedNames.prefix(25))
    }
    
    return joinedNames
}

// MARK: - Password Security Transformations
func randomlyCapitalizeLetters(in password: inout [Character], count: Int) {
    let letterIndices = password.enumerated().compactMap { index, char in
        char.isLetter ? index : nil
    }
    
    let indicesToCapitalize = Array(letterIndices.shuffled().prefix(count))
    
    for index in indicesToCapitalize {
        password[index] = Character(password[index].uppercased())
    }
}

func insertRandomNumbers(into password: inout [Character], count: Int) {
    let numbers = "0123456789"
    
    for _ in 0..<count {
        let randomNumber = numbers.randomElement()!
        let insertIndex = Int.random(in: 0...password.count)
        password.insert(randomNumber, at: insertIndex)
    }
}

func replaceLettersWithSymbols(in password: inout [Character], count: Int) {
    let symbols = "!@#$%^&*()-_=+[]{}|;:,.<>?"
    let letterIndices = password.enumerated().compactMap { index, char in
        char.isLetter ? index : nil
    }
    
    let indicesToReplace = Array(letterIndices.shuffled().prefix(count))
    
    for index in indicesToReplace {
        password[index] = symbols.randomElement()!
    }
}

func removeRepeatingLetters(in password: inout [Character]) {
    let numbers = "0123456789"
    var seenLetters = Set<Character>()
    var previousChar: Character?
    
    for i in 0..<password.count {
        let currentChar = password[i].lowercased().first!
        
        if currentChar.isLetter {
            if let prev = previousChar, prev == currentChar || seenLetters.contains(currentChar) {
                password[i] = numbers.randomElement()!
            } else {
                seenLetters.insert(currentChar)
            }
            previousChar = currentChar
        }
    }
}

// MARK: - Complete Password Generation
func generateSecurePassword(from catNames: [String]) -> String {
    // Step 1: Select 3-5 cat names
    let nameCount = Int.random(in: 3...5)
    let selectedNames = selectRandomCatNames(from: catNames, count: nameCount)
    
    // Step 2: Create base phrase
    let basePhrase = createBasePhrase(from: selectedNames)
    var password = Array(basePhrase.lowercased())
    
    // Step 3: Apply security transformations
    randomlyCapitalizeLetters(in: &password, count: 3)
    insertRandomNumbers(into: &password, count: Int.random(in: 3...5))
    replaceLettersWithSymbols(in: &password, count: 2)
    removeRepeatingLetters(in: &password)
    
    return String(password)
}

// MARK: - Kolmogorov Complexity Analysis
func calculateShannonEntropy(of string: String) -> Double {
    let charCounts = string.reduce(into: [Character: Int]()) { counts, char in
        counts[char, default: 0] += 1
    }
    
    let length = Double(string.count)
    let entropy = charCounts.values.reduce(0.0) { result, count in
        let probability = Double(count) / length
        return result - (probability * log2(probability))
    }
    
    return entropy
}

func calculateCompressionRatio(of string: String) -> Double {
    // Simple run-length encoding approximation
    var compressed = 0
    var previous: Character?
    var runLength = 1
    
    for char in string {
        if char == previous {
            runLength += 1
        } else {
            compressed += runLength > 1 ? 2 : 1
            runLength = 1
            previous = char
        }
    }
    compressed += runLength > 1 ? 2 : 1
    
    return 1.0 - (Double(compressed) / Double(string.count))
}

func calculatePatternComplexity(of string: String) -> Double {
    let substrings = getSubstrings(from: string, maxLength: 4)
    let uniqueSubstrings = Set(substrings)
    
    if substrings.isEmpty { return 0.0 }
    
    return Double(uniqueSubstrings.count) / Double(substrings.count)
}

func getSubstrings(from string: String, maxLength: Int) -> [String] {
    let chars = Array(string)
    var substrings: [String] = []
    
    for length in 2...min(maxLength, chars.count) {
        for start in 0...(chars.count - length) {
            let substring = String(chars[start..<start + length])
            substrings.append(substring)
        }
    }
    
    return substrings
}

func calculateCharacterDiversity(of string: String) -> Double {
    let uniqueChars = Set(string)
    let hasLower = uniqueChars.contains { $0.isLowercase }
    let hasUpper = uniqueChars.contains { $0.isUppercase }
    let hasDigits = uniqueChars.contains { $0.isNumber }
    let hasSymbols = uniqueChars.contains { !$0.isLetter && !$0.isNumber }
    
    let categories = [hasLower, hasUpper, hasDigits, hasSymbols].filter { $0 }.count
    return Double(categories) / 4.0
}

func analyzeComplexity(of password: String) -> (score: Double, analysis: String) {
    let entropy = calculateShannonEntropy(of: password)
    let compressionRatio = calculateCompressionRatio(of: password)
    let patternComplexity = calculatePatternComplexity(of: password)
    let diversity = calculateCharacterDiversity(of: password)
    
    // Weighted complexity score
    let score = (entropy * 0.3) + (compressionRatio * 0.25) + 
                (patternComplexity * 0.2) + (diversity * 0.15) + 
                (min(Double(password.count) / 25.0, 1.0) * 0.1)
    
    let finalScore = min(score, 10.0)
    
    let analysis = """
    Kolmogorov Complexity Analysis:
    - Password: \(password)
    - Length: \(password.count) characters
    - Shannon Entropy: \(String(format: "%.3f", entropy)) bits
    - Compression Resistance: \(String(format: "%.1f", compressionRatio * 100))%
    - Pattern Uniqueness: \(String(format: "%.1f", patternComplexity * 100))%
    - Character Diversity: \(String(format: "%.1f", diversity * 100))%
    - Overall Complexity Score: \(String(format: "%.2f", finalScore))/10.0
    """
    
    return (finalScore, analysis)
}

// MARK: - Test Functions (Include here for single-file approach)

// Test Helper Functions
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

// Specific test functions
func testLoadCatNames() {
    print("\n🧪 Testing Cat Name Loading...")
    
    let catNames = loadCatNames(from: "catNamesText.txt")
    assert(!catNames.isEmpty, "Should load cat names from catNamesText.txt")
    assert(catNames.count > 1000, "Should load a substantial number of cat names")
    
    let nonEmptyNames = catNames.filter { !$0.isEmpty }
    assertEqual(nonEmptyNames.count, catNames.count, "All loaded names should be non-empty")
    
    let emptyNames = loadCatNames(from: "nonexistent.txt")
    assertEqual(emptyNames.count, 0, "Should return empty array for non-existent file")
    
    print("Cat names loaded: \(catNames.count)")
    print("First few names: \(Array(catNames.prefix(5)))")
}

func testCompletePasswordGeneration() {
    print("\n🧪 Testing Complete Password Generation...")
    
    let testNames = ["Fluffy", "Whiskers", "Shadow", "Mittens", "Tiger", "Luna", "Max", "Bella"]
    
    for i in 1...3 {
        let password = generateSecurePassword(from: testNames)
        
        print("Generated password \(i): \(password)")
        
        assert(password.count >= 10, "Password should be at least 10 characters")
        assert(password.count <= 35, "Password should not exceed 35 characters")
        
        let hasNumbers = password.contains { $0.isNumber }
        let hasLetters = password.contains { $0.isLetter }
        let hasSymbols = password.contains { !$0.isLetter && !$0.isNumber }
        
        assert(hasNumbers, "Password should contain numbers")
        assert(hasLetters, "Password should contain letters")
        assert(hasSymbols, "Password should contain symbols")
        
        let (score, analysis) = analyzeComplexity(of: password)
        assert(score >= 0.0 && score <= 10.0, "Complexity score should be valid")
        assert(!analysis.isEmpty, "Analysis should not be empty")
    }
}

func runBasicTests() {
    print("🚀 Running Basic MeowPassword Tests")
    print("===================================")
    
    testLoadCatNames()
    testCompletePasswordGeneration()
    
    print("\n🎉 Basic Tests Complete!")
    print("========================")
}

// MARK: - Main Program
func main() {
    // Check for test mode
    if CommandLine.arguments.contains("--test") {
        runBasicTests()
        return
    }
    
    print("🐾 MeowPassword Generator")
    
    // Load cat names
    let catNames = loadCatNames(from: "catNamesText.txt")
    guard !catNames.isEmpty else {
        print("Error: No cat names loaded. Please ensure catNamesText.txt exists.")
        return
    }
    
    print("📝 Loaded \(catNames.count) cat names")
    print("🔄 Generating 5 secure password candidates...\n")
    
    // Generate 5 password candidates
    var candidates: [(password: String, score: Double, analysis: String)] = []
    
    for i in 1...5 {
        let password = generateSecurePassword(from: catNames)
        let (score, analysis) = analyzeComplexity(of: password)
        candidates.append((password, score, analysis))
        
        print("🔐 Candidate \(i): \(password)")
        print("   Complexity Score: \(String(format: "%.2f", score))/10.0\n")
    }
    
    // Select the most secure password
    guard let bestCandidate = candidates.max(by: { $0.score < $1.score }) else {
        print("Error: Could not select best password")
        return
    }
    
    print("🏆 Most Secure Password Selected:")
    print("🔐 \(bestCandidate.password)")
    print("📊 Final Complexity Score: \(String(format: "%.2f", bestCandidate.score))/10.0\n")
    print(bestCandidate.analysis)
    
    // Option to copy to clipboard (basic approach)
    if CommandLine.arguments.contains("--copy") {
        #if os(macOS)
        let task = Process()
        task.launchPath = "/usr/bin/pbcopy"
        let pipe = Pipe()
        task.standardInput = pipe
        task.launch()
        
        pipe.fileHandleForWriting.write(bestCandidate.password.data(using: .utf8)!)
        pipe.fileHandleForWriting.closeFile()
        task.waitUntilExit()
        
        print("\n📋 Password copied to clipboard!")
        #else
        print("\n❌ Clipboard functionality only available on macOS")
        #endif
    } else {
        print("\n💡 Use 'swift MeowPassword/main.swift --copy' to copy password to clipboard")
    }
}

// Run the program
main()

