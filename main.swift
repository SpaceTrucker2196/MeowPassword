//
//  main.swift
//  MeowPassword
//
//  Created by Jeffrey Kunzelman on 8/23/25.
//

import Foundation

// MARK: - ASCII Art and Lolcat Theme
let lolcatArt = """
                               __
                         _,-;'''`'-,.
                      _/',  `;  `;    `\\
      ,        _..,-''    '   `  `      `\\
     | ;._.,,-' .| |,_        ,,          `\\
     | `;'      ;' ;, `,   ; |    '  '  .   \\
     `; __`  ,'__  ` ,  ` ;  |      ;        \\
     ; (6_);  (6_) ; |   ,    \\        '      |       /
    ;;   _,' ,.    ` `,   '    `-._           |   __//_________
     ,;.=..`_..=.,' -'          ,''        _,--''------''''
_pb__\\,`"=,,,=="',___,,,-----'''----'_'_'_''-;''
-----------------------''''''\\  \\'''''   )   /'
                              `\\`,,,___/__/'_____,
                                `--,,,--,-,'''\\  
                               __,,-' /'       `
                             /'_,,--''
                            | (
                             `'

"""

// MARK: - Configuration Structure
struct PasswordConfig {
    let numNumbers: Int
    let numSymbols: Int
    let maxLength: Int
    let showTests: Bool
    let copyToClipboard: Bool
    
    init(arguments: [String]) {
        var numNumbers = Int.random(in: 3...5)  // Default range
        var numSymbols = 2  // Default value
        var maxLength = 25  // Default max length
        var showTests = false
        var copyToClipboard = false
        
        // Parse command line arguments
        for i in 0..<arguments.count {
            switch arguments[i] {
            case "--numbers":
                if i + 1 < arguments.count, let value = Int(arguments[i + 1]) {
                    numNumbers = max(1, min(10, value))  // Clamp between 1-10
                }
            case "--symbols":
                if i + 1 < arguments.count, let value = Int(arguments[i + 1]) {
                    numSymbols = max(1, min(10, value))  // Clamp between 1-10
                }
            case "--max-length":
                if i + 1 < arguments.count, let value = Int(arguments[i + 1]) {
                    maxLength = max(15, min(50, value))  // Clamp between 15-50
                }
            case "--test":
                showTests = true
            case "--copy":
                copyToClipboard = true
            default:
                break
            }
        }
        
        self.numNumbers = numNumbers
        self.numSymbols = numSymbols
        self.maxLength = maxLength
        self.showTests = showTests
        self.copyToClipboard = copyToClipboard
    }
}

// MARK: - Embedded Cat Names Data (automatically generated)
// This file contains all cat names embedded directly in the executable
func getEmbeddedCatNames() -> [String] {
    // Read the embedded cat names from the generated Swift file
    return embeddedCatNames
}

// MARK: - Cat Name Loading
func loadCatNames(from filePath: String? = nil) -> [String] {
    // Always use embedded cat names for production builds
    return getEmbeddedCatNames()
}

// MARK: - Random Cat Name Selection
func selectRandomCatNames(from catNames: [String], count: Int) -> [String] {
    guard !catNames.isEmpty, count > 0 else { return [] }
    
    let actualCount = min(count, catNames.count)
    return Array(catNames.shuffled().prefix(actualCount))
}

// MARK: - Base Phrase Creation
func createBasePhrase(from catNames: [String], maxLength: Int) -> String {
    let joinedNames = catNames.joined()
    
    // Ensure phrase is between 15 and maxLength characters
    if joinedNames.count < 15 {
        // If too short, try adding more names
        let additionalNames = selectRandomCatNames(from: catNames, count: 2)
        let extended = joinedNames + additionalNames.joined()
        return String(extended.prefix(maxLength))
    } else if joinedNames.count > maxLength {
        return String(joinedNames.prefix(maxLength))
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
func generateSecurePassword(from catNames: [String], config: PasswordConfig) -> String {
    // Step 1: Select 3-5 cat names
    let nameCount = Int.random(in: 3...5)
    let selectedNames = selectRandomCatNames(from: catNames, count: nameCount)
    
    // Step 2: Create base phrase
    let basePhrase = createBasePhrase(from: selectedNames, maxLength: config.maxLength)
    var password = Array(basePhrase.lowercased())
    
    // Step 3: Apply security transformations
    randomlyCapitalizeLetters(in: &password, count: 3)
    insertRandomNumbers(into: &password, count: config.numNumbers)
    replaceLettersWithSymbols(in: &password, count: config.numSymbols)
    removeRepeatingLetters(in: &password)
    
    // Ensure final password doesn't exceed max length
    if password.count > config.maxLength {
        password = Array(password.prefix(config.maxLength))
    }
    
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
        print("PASS: \(message)")
    } else {
        print("FAIL: \(message)")
    }
}

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    if actual == expected {
        print("PASS: \(message)")
    } else {
        print("FAIL: \(message) - Expected: \(expected), Got: \(actual)")
    }
}

// Specific test functions
func testLoadCatNames() {
    print("\nTesting Cat Name Loading...")
    
    let catNames = loadCatNames()
    assert(!catNames.isEmpty, "Should load cat names from embedded data")
    assert(catNames.count > 100, "Should load a substantial number of cat names")
    
    let nonEmptyNames = catNames.filter { !$0.isEmpty }
    assertEqual(nonEmptyNames.count, catNames.count, "All loaded names should be non-empty")
    
    let embeddedNames = loadCatNames(from: nil)  
    assertEqual(embeddedNames.count, catNames.count, "Should return same count for embedded names")
    
    print("Cat names loaded: \(catNames.count)")
    print("First few names: \(Array(catNames.prefix(5)))")
}

func testCompletePasswordGeneration() {
    print("\nTesting Complete Password Generation...")
    
    let testNames = ["Fluffy", "Whiskers", "Shadow", "Mittens", "Tiger", "Luna", "Max", "Bella"]
    let config = PasswordConfig(arguments: [])
    
    for i in 1...3 {
        let password = generateSecurePassword(from: testNames, config: config)
        
        print("Generated password \(i): \(password)")
        
        assert(password.count >= 10, "Password should be at least 10 characters")
        assert(password.count <= config.maxLength + 10, "Password should not greatly exceed max length")
        
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
    print("Running Basic MeowPassword Tests")
    print("=================================")
    
    testLoadCatNames()
    testCompletePasswordGeneration()
    
    print("\nBasic Tests Complete!")
    print("=====================")
}

// MARK: - Help Function
func showHelp() {
    print("MeowPassword - Lolcat-themed secure password generator")
    print("")
    print("Usage: meowpass [options]")
    print("")
    print("Options:")
    print("  --numbers N      Number of random numbers to insert (1-10, default: 3-5)")
    print("  --symbols N      Number of symbols to insert (1-10, default: 2)")
    print("  --max-length N   Maximum password length (15-50, default: 25)")
    print("  --test           Run tests")
    print("  --copy           Copy password to clipboard (macOS only)")
    print("  --help           Show this help message")
    print("")
    print("Examples:")
    print("  meowpass")
    print("  meowpass --numbers 4 --symbols 3 --max-length 30")
    print("  meowpass --test")
}

// MARK: - Main Program
func main() {
    let config = PasswordConfig(arguments: CommandLine.arguments)
    
    // Check for help
    if CommandLine.arguments.contains("--help") {
        showHelp()
        return
    }
    
    // Check for test mode
    if config.showTests {
        runBasicTests()
        return
    }
    
    // Show ASCII art and title
    print(lolcatArt)
    print("MEOWPASSWORD - Lolcat Secure Password Generator")
    print("===============================================")
    
    // Load cat names (now from embedded data)
    let catNames = loadCatNames()
    guard !catNames.isEmpty else {
        print("ERROR: No cat names loaded from embedded data.")
        return
    }
    
    print("Loaded \(catNames.count) cat names")
    print("Generating 5 secure password candidates...")
    print("Config: \(config.numNumbers) numbers, \(config.numSymbols) symbols, max length \(config.maxLength)")
    print("")
    
    // Generate 5 password candidates
    var candidates: [(password: String, score: Double, analysis: String)] = []
    
    for i in 1...5 {
        let password = generateSecurePassword(from: catNames, config: config)
        let (score, analysis) = analyzeComplexity(of: password)
        candidates.append((password, score, analysis))
        
        print("Candidate \(i): \(password)")
        print("   Complexity Score: \(String(format: "%.2f", score))/10.0")
        print("")
    }
    
    // Select the most secure password
    guard let bestCandidate = candidates.max(by: { $0.score < $1.score }) else {
        print("ERROR: Could not select best password")
        return
    }
    
    print("MOST SECURE PASSWORD SELECTED:")
    print("Password: \(bestCandidate.password)")
    print("Final Complexity Score: \(String(format: "%.2f", bestCandidate.score))/10.0")
    print("")
    print(bestCandidate.analysis)
    
    // Option to copy to clipboard (basic approach)
    if config.copyToClipboard {
        #if os(macOS)
        let task = Process()
        task.launchPath = "/usr/bin/pbcopy"
        let pipe = Pipe()
        task.standardInput = pipe
        task.launch()
        
        pipe.fileHandleForWriting.write(bestCandidate.password.data(using: .utf8)!)
        pipe.fileHandleForWriting.closeFile()
        task.waitUntilExit()
        
        print("")
        print("Password copied to clipboard!")
        #else
        print("")
        print("Clipboard functionality only available on macOS")
        #endif
    } else {
        print("")
        print("Use 'meowpass --copy' to copy password to clipboard")
    }
}

// Run the program
main()

