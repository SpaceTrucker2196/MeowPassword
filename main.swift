//
//  main.swift
//  MeowPassword
//
//  Created by Jeffrey Kunzelman on 8/23/25.
//

import Foundation

// MARK: - ASCII Art and Lolcat Theme
let lolcatArt = """
                         _,-;'''`' - .
                      _/',  `;  `;    \\
      ,        _..,-''    '   `  `      `\\
     | ;._.,,-' .| |,_     '   '         `\\
     | `;'      ;' ;, `,   ; |    '  '  .   \\
     `; __`  ,'__  ` ,  ` ;  |      ;        \\
     ; (6_);  (6_) ; |   ,    \\        '      |       
    ;;   _,6 ,.    ` `,   '    `-._           //   
     ,;.=..`_..=.,' -'          ,''        _,//
_00_____`"=,,,=="',___,,,-----'''----'_'_'_''______00_
	Meow Password Generators of Secure Relavant
                               __,,-' /'       
                             /'_,,--''
                            | (
                             `'
"""
// MARK: - Version / Update Metadata

let meowpassVersion = "1.0.0"
let meowpassGithubOwner = "SpaceTrucker2196"
let meowpassGithubRepo = "MeowPassword"

// MARK: - Configuration Structure

/**
 * Configuration structure for password generation parameters
 * Handles command-line argument parsing and parameter validation
 */
struct PasswordConfig {
    let numNumbers: Int     // Number of random numbers to insert (1-10)
    let numSymbols: Int     // Number of random symbols to insert (1-10)
    let maxLength: Int      // Maximum password length (15-50)
    let showTests: Bool     // Whether to run test mode
    let copyToClipboard: Bool // Whether to copy result to clipboard
    let psssst: Bool        // Silent mode — copy winner, print nothing
    let showHelp: Bool      // Whether the user asked for help
    let checkUpdate: Bool   // Whether to check GitHub for updates
    let analyzeString: String? // If set, score this string instead of generating

    /**
     * Initialize configuration from command line arguments
     * @param arguments: Array of command line arguments
     */
    init(arguments: [String]) {
        var numNumbers = Int.random(in: 1...4)  // Default range as specified in requirements
        var numSymbols = 2  // Default value as specified in requirements
        var maxLength = 25  // Default max length as specified in requirements
        var showTests = false
        var copyToClipboard = false
        var psssst = false
        var showHelp = false
        var checkUpdate = false
        var analyzeString: String? = nil

        // Parse command line arguments with validation
        var i = 0
        while i < arguments.count {
            switch arguments[i] {
            case "--numbers":
                if i + 1 < arguments.count, let value = Int(arguments[i + 1]) {
                    numNumbers = max(1, min(10, value))  // Clamp between 1-10
                    i += 1
                }
            case "--symbols":
                if i + 1 < arguments.count, let value = Int(arguments[i + 1]) {
                    numSymbols = max(1, min(10, value))  // Clamp between 1-10
                    i += 1
                }
            case "--max-length":
                if i + 1 < arguments.count, let value = Int(arguments[i + 1]) {
                    maxLength = max(15, min(50, value))  // Clamp between 15-50
                    i += 1
                }
            case "--test":
                showTests = true
            case "--copy":
                copyToClipboard = true
            case "--psssst", "-p":
                psssst = true
                copyToClipboard = true
            case "--help", "-h":
                showHelp = true
            case "--update":
                checkUpdate = true
            case "--analyze", "-a":
                if i + 1 < arguments.count {
                    analyzeString = arguments[i + 1]
                    i += 1
                }
            default:
                break
            }
            i += 1
        }

        self.numNumbers = numNumbers
        self.numSymbols = numSymbols
        self.maxLength = maxLength
        self.showTests = showTests
        self.copyToClipboard = copyToClipboard
        self.psssst = psssst
        self.showHelp = showHelp
        self.checkUpdate = checkUpdate
        self.analyzeString = analyzeString
    }
}

// MARK: - Embedded Cat Names Data

/**
 * Get embedded cat names from the compiled-in data
 * Cat names are embedded during the build process to create a self-contained executable
 * @return Array of cat names embedded during build process
 */
func getEmbeddedCatNames() -> [String] {
    // Read the embedded cat names from the generated Swift file
    return embeddedCatNames
}

/**
 * Load cat names from embedded data (legacy interface for compatibility)
 * This function maintains backward compatibility while using embedded data
 * @param filePath: Ignored parameter - always uses embedded data
 * @return Array of cat names from embedded data
 */
func loadCatNames(from filePath: String? = nil) -> [String] {
    // Always use embedded cat names for production builds
    return getEmbeddedCatNames()
}

// MARK: - Cat Name Selection and Processing

/**
 * Select random cat names from the available pool
 * @param catNames: Array of available cat names to choose from
 * @param count: Number of names to select (will be clamped to available count)
 * @return Array of randomly selected cat names
 */
func selectRandomCatNames(from catNames: [String], count: Int) -> [String] {
    guard !catNames.isEmpty, count > 0 else { return [] }
    
    let actualCount = min(count, catNames.count)
    return Array(catNames.shuffled().prefix(actualCount))
}

/**
 * Create base phrase from selected cat names with length constraints
 * Ensures the phrase meets the 15-25 character requirement from specifications
 * @param catNames: Array of selected cat names to combine
 * @param maxLength: Maximum allowed length for the phrase
 * @return Base phrase string within specified length constraints
 */
func createBasePhrase(from catNames: [String], maxLength: Int) -> String {
    let joinedNames = catNames.joined()
    
    // Ensure phrase is between 15 and maxLength characters as per specifications
    if joinedNames.count < 15 {
        // If too short, try adding more names to meet minimum length requirement
        let additionalNames = selectRandomCatNames(from: catNames, count: 5)
        let extended = joinedNames + additionalNames.joined()
        return String(extended.prefix(maxLength))
    } else if joinedNames.count > maxLength {
        return String(joinedNames.prefix(maxLength))
    }
    return joinedNames
}

// MARK: - Password Security Transformations

/**
 * Randomly capitalize letters in the password array
 * Implements the "3 letters randomly capitalized" requirement
 * @param password: Mutable array of characters to modify
 * @param count: Number of letters to capitalize (typically 3)
 */
func randomlyCapitalizeLetters(in password: inout [Character], count: Int) {
    let letterIndices = password.enumerated().compactMap { index, char in
        char.isLetter ? index : nil
    }
    
    let indicesToCapitalize = Array(letterIndices.shuffled().prefix(count))
    
    for index in indicesToCapitalize {
        password[index] = Character(password[index].uppercased())
    }
}

/**
 * Insert random numbers into the password at random positions
 * Implements the "3-5 numbers inserted randomly" requirement
 * @param password: Mutable array of characters to modify
 * @param count: Number of random numbers to insert
 */
func insertRandomNumbers(into password: inout [Character], count: Int) {
    let numbers = "0123456789"
    
    for _ in 0..<count {
        let randomNumber = numbers.randomElement()!
        let insertIndex = Int.random(in: 0...password.count)
        password.insert(randomNumber, at: insertIndex)
    }
}

/**
 * Replace letters with symbols at random positions
 * Implements the "2 symbols randomly replacing letters" requirement
 * @param password: Mutable array of characters to modify
 * @param count: Number of letters to replace with symbols (typically 2)
 */
func replaceLettersWithSymbols(in password: inout [Character], count: Int) {
    let symbols = "!@#$%^&*()-_=+[]{;:.<>?"
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
    let nameCount = Int.random(in: 2...6)
    let selectedNames = selectRandomCatNames(from: catNames, count: nameCount)
    
    // Step 2: Create base phrase
    let basePhrase = createBasePhrase(from: selectedNames, maxLength: config.maxLength)
	var password = Array(
    basePhrase
        .lowercased()
        .replacingOccurrences(of: " ", with: "")
)    
    // Step 3: Apply security transformations
    randomlyCapitalizeLetters(in: &password, count: 3)
    insertRandomNumbers(into: &password, count: config.numNumbers)
    replaceLettersWithSymbols(in: &password, count: config.numSymbols)
 //   removeRepeatingLetters(in: &password)
    
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

    // Normalize each signal to [0, 1] so the weighted sum can actually
    // land near 10 for a strong password. Higher score = better.
    let entropyN     = min(entropy / 4.5, 1.0)              // ~4.5 bits/char is very high
    let compressionN = max(min(compressionRatio, 1.0), 0.0)  // clamp — RLE ratio can go negative
    let patternN     = patternComplexity                     // already [0, 1]
    let diversityN   = diversity                             // already [0, 1]
    let lengthN      = min(Double(password.count) / 25.0, 1.0)

    let unit = (entropyN * 0.30) +
               (compressionN * 0.10) +
               (patternN * 0.25) +
               (diversityN * 0.25) +
               (lengthN * 0.10)

    let finalScore = max(0.0, min(unit * 10.0, 10.0))
    
   let analysis = """
    Meow Complexity Analysis:
    - Password: \(password)
    - Tail Size: \(password.count) cm
    - Ball of Yarn Entropy: \(String(format: "%.3f", entropy)) bits
    - Mashing Resistance: \(String(format: "%.1f", compressionRatio * 100))%
    - Shiny Foil Ball Uniqueness: \(String(format: "%.1f", patternComplexity * 100))%
    - Percent of Organic NonGMO Catnip: \(String(format: "%.1f", diversity * 100))%
    - Overall Relavency: \(String(format: "%.2f", finalScore))/10.0
    """
    
    return (finalScore, analysis)
}

// MARK: - Test Functions

/**
 * Helper function to assert test conditions and print results
 * @param condition: Boolean condition to test
 * @param message: Description of what is being tested
 */
func assert(_ condition: Bool, _ message: String) {
    if condition {
        print("PASS: \(message)")
    } else {
        print("FAIL: \(message)")
    }
}

/**
 * Helper function to assert equality and print results
 * @param actual: The actual value received
 * @param expected: The expected value
 * @param message: Description of what is being tested
 */
func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    if actual == expected {
        print("PASS: \(message)")
    } else {
        print("FAIL: \(message) - Expected: \(expected), Got: \(actual)")
    }
}

/**
 * Test the cat name loading functionality
 * Verifies that embedded cat names are properly loaded and accessible
 */
func testLoadCatNames() {
    print("\nTesting Cat Name Loading...")
    
    let catNames = loadCatNames()
    assert(!catNames.isEmpty, "Should Meow load cat names from embedded data")
    assert(catNames.count > 100, "Should load a substantial Meow number of cat names")
    
    let nonEmptyNames = catNames.filter { !$0.isEmpty }
    assertEqual(nonEmptyNames.count, catNames.count, "All Meow Meow loaded names should be non-empty")
    
    // Test consistency of embedded loading
    let embeddedNames = loadCatNames(from: nil)  
    assertEqual(embeddedNames.count, catNames.count, "Should return same Meow count for embedded names")
    
    print("Cat names loaded meow: \(catNames.count)")
    print("First few names: \(Array(catNames.prefix(5)))")
}

/**
 * Test the complete password generation process
 * Validates that passwords meet all security requirements
 */
func testCompletePasswordGeneration() {
    print("\nTesting MeowMeow Complete Password Generation...")
    
    let testNames = ["Fluffy", "Whiskers", "Shadow", "Mittens", "Tiger", "Luna", "Max", "Bella"]
    let config = PasswordConfig(arguments: [])
    
    for i in 1...3 {
        let password = generateSecurePassword(from: testNames, config: config)
        
        print("Generated password \(i): \(password)")
        
        assert(password.count >= 10, "MeowPassword should be at least 10 characters")
        assert(password.count <= config.maxLength + 10, "Password should not greatly exceed Meow max length")
        
        let hasNumbers = password.contains { $0.isNumber }
        let hasLetters = password.contains { $0.isLetter }
        let hasSymbols = password.contains { !$0.isLetter && !$0.isNumber }
        
        assert(hasNumbers, "Password should contain meow numbers")
        assert(hasLetters, "Password meow should contain letters")
        assert(hasSymbols, "Password should contain meow symbols")
        
        let (score, analysis) = analyzeComplexity(of: password)
        assert(score >= 0.0 && score <= 10.0, "Complexity score should be meow valid")
        assert(!analysis.isEmpty, "Analysis should not be meow empty")
    }
}

/**
 * Run all basic tests for the MeowPassword system
 * Executes comprehensive testing of all core functionality
 */
func runBasicTests() {
    print("Running Basic MeowPassword Tests")
    print("=================================")
    
    testLoadCatNames()
    testCompletePasswordGeneration()
    
    print("\nMeow Basic Tests Complete!")
    print("=====================")
}

// MARK: - Help Function

/**
 * Display help information for command-line usage
 * Shows all available options and example usage
 */
func showHelp() {
    print("MeowPassword - Cat Dynamic Secure Password Generator")
    print("")
    print("Usage: meowpass [options]")
    print("")
    print("Options:")
    print("  --numbers N      Number of random numbers to insert (1-10, default: 1-4)")
    print("  --symbols N      Number of symbols to insert (1-10, default: 2)")
    print("  --max-length N   Maximum password length (15-50, default: 25)")
    print("  --test           Run tests")
    print("  --copy           Copy password to clipboard (pbcopy / xclip / wl-copy)")
    print("  --psssst, -p     Copy password to clipboard without displaying it")
    print("                   (more secure - password won't be shown in clear text)")
    print("  --analyze, -a S  Analyze a string's meow complexity (treats it like a password)")
    print("  --update         Check GitHub for updates and install if available")
    print("  --help, -h       Show this help message")
    print("")
    print("Examples:")
    print("  meowpass")
    print("  meowpass --numbers 4 --symbols 3 --max-length 30")
    print("  meowpass --analyze \"MyP@ssw0rd!\"")
    print("  meowpass --test")
}

// MARK: - Clipboard

/**
 * Copy the given string to the system clipboard.
 * macOS: pbcopy. Linux: xclip, else wl-copy.
 * Returns true on success, false if no clipboard tool is available.
 */
@discardableResult
func copyToClipboard(_ text: String) -> Bool {
    #if os(macOS)
    return runPipe(command: "/usr/bin/pbcopy", arguments: [], input: text)
    #elseif os(Linux)
    if let xclip = which("xclip") {
        return runPipe(command: xclip, arguments: ["-selection", "clipboard"], input: text)
    }
    if let wlCopy = which("wl-copy") {
        return runPipe(command: wlCopy, arguments: [], input: text)
    }
    return false
    #else
    return false
    #endif
}

/**
 * Pipe `input` into the given command's stdin. Returns true if exit code == 0.
 */
private func runPipe(command: String, arguments: [String], input: String) -> Bool {
    let task = Process()
    task.launchPath = command
    task.arguments = arguments
    let pipe = Pipe()
    task.standardInput = pipe
    do {
        try task.run()
    } catch {
        return false
    }
    if let data = input.data(using: .utf8) {
        pipe.fileHandleForWriting.write(data)
    }
    pipe.fileHandleForWriting.closeFile()
    task.waitUntilExit()
    return task.terminationStatus == 0
}

#if os(Linux)
/**
 * Resolve `name` via `command -v`. Returns the path or nil if not found.
 */
private func which(_ name: String) -> String? {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", "command -v \(name)"]
    let pipe = Pipe()
    task.standardOutput = pipe
    do {
        try task.run()
    } catch {
        return nil
    }
    task.waitUntilExit()
    guard task.terminationStatus == 0 else { return nil }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    return (path?.isEmpty == false) ? path : nil
}
#endif

func clipboardMissingHint() -> String {
    #if os(macOS)
    return "Clipboard functionality requires pbcopy (default on macOS)"
    #elseif os(Linux)
    return "Clipboard functionality requires xclip or wl-copy (apt install xclip)"
    #else
    return "Clipboard functionality is not supported on this platform"
    #endif
}

// MARK: - Analyze Mode

/**
 * Return a catified verdict line for a given complexity score.
 * Higher score = more complex string = better.
 */
func analyzeVerdict(for score: Double) -> String {
    if score < 3.0 {
        return "Hiss! A kitten could paw this one open! Try a meowpass-generated password instead!"
    } else if score < 5.0 {
        return "Meow... this string is a bit too easy for a clever cat to guess."
    } else if score < 7.0 {
        return "Not bad, hooman! This string has decent whisker-resistance."
    } else {
        return "Purrfect! This string is fur-midably complex. Even the cleverest cats can't crack it!"
    }
}

// MARK: - Update Check

/**
 * Compare two dotted version strings ("1.2.3" vs "1.2.4").
 * Returns 1 if latest > current, 0 if equal, -1 if latest < current.
 */
func compareVersions(_ current: String, _ latest: String) -> Int {
    let cur = current.split(separator: ".").map { Int($0) ?? 0 }
    let lat = latest.split(separator: ".").map { Int($0) ?? 0 }
    let count = max(cur.count, lat.count)
    for i in 0..<count {
        let c = i < cur.count ? cur[i] : 0
        let l = i < lat.count ? lat[i] : 0
        if l != c { return l > c ? 1 : -1 }
    }
    return 0
}

/**
 * Extract the tag_name value from a GitHub release JSON blob.
 * Strips a leading "v" if present.
 */
func parseTagFromJSON(_ json: String) -> String? {
    guard let range = json.range(of: "\"tag_name\"") else { return nil }
    var rest = json[range.upperBound...]
    // Skip whitespace and colon
    while let c = rest.first, c == " " || c == "\t" || c == ":" {
        rest = rest.dropFirst()
    }
    guard rest.first == "\"" else { return nil }
    rest = rest.dropFirst()
    if let c = rest.first, c == "v" || c == "V" {
        rest = rest.dropFirst()
    }
    guard let endQuote = rest.firstIndex(of: "\"") else { return nil }
    let tag = String(rest[..<endQuote])
    return tag.isEmpty ? nil : tag
}

/**
 * A version string is valid if it contains only digits and dots.
 */
func isValidVersion(_ v: String) -> Bool {
    guard !v.isEmpty else { return false }
    return v.allSatisfy { $0.isNumber || $0 == "." }
}

/**
 * Run a shell command and capture stdout. Returns nil on failure.
 */
private func shellCapture(_ command: String) -> String? {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", command]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.standardError
    do {
        try task.run()
    } catch {
        return nil
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    guard task.terminationStatus == 0 else { return nil }
    return String(data: data, encoding: .utf8)
}

/**
 * Check GitHub releases for a newer version and optionally install it.
 * Returns 0 on success (or no update), non-zero on error.
 */
func checkForUpdate() -> Int32 {
    print("Checking for updates...")

    let url = "https://api.github.com/repos/\(meowpassGithubOwner)/\(meowpassGithubRepo)/releases/latest"
    guard let response = shellCapture("curl -s '\(url)'"), !response.isEmpty else {
        FileHandle.standardError.write("Error: No response from GitHub API.\n".data(using: .utf8)!)
        return -1
    }

    guard let latest = parseTagFromJSON(response) else {
        FileHandle.standardError.write("Error: Could not parse version from GitHub response.\n".data(using: .utf8)!)
        return -1
    }

    guard isValidVersion(latest) else {
        FileHandle.standardError.write("Error: Invalid version format received from GitHub.\n".data(using: .utf8)!)
        return -1
    }

    print("Current version: \(meowpassVersion)")
    print("Latest  version: \(latest)")

    if compareVersions(meowpassVersion, latest) <= 0 {
        print("You are already running the latest version. Meow!")
        return 0
    }

    print("")
    print("A new version (\(latest)) is available!")
    print("Would you like to download, build, and install it? [y/N] ", terminator: "")

    guard let line = readLine(), let first = line.first, first == "y" || first == "Y" else {
        print("Update skipped.")
        return 0
    }

    let installCmd = """
    set -e && \
    TMPDIR=$(mktemp -d) && \
    echo "Downloading v\(latest)..." && \
    curl -sL https://github.com/\(meowpassGithubOwner)/\(meowpassGithubRepo)/archive/refs/tags/v\(latest).tar.gz | tar xz -C "$TMPDIR" && \
    echo "Building..." && \
    (cd "$TMPDIR/\(meowpassGithubRepo)-\(latest)" && swift build -c release) && \
    echo "Installing (may require sudo)..." && \
    sudo install "$TMPDIR/\(meowpassGithubRepo)-\(latest)/.build/release/meowpass" /usr/local/bin/meowpass && \
    rm -rf "$TMPDIR" && \
    echo "Update complete! Meow!"
    """

    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", installCmd]
    do {
        try task.run()
    } catch {
        FileHandle.standardError.write("Error: Update failed to launch.\n".data(using: .utf8)!)
        return -1
    }
    task.waitUntilExit()
    return task.terminationStatus == 0 ? 0 : -1
}

// MARK: - Main Program
func main() -> Int32 {
    let config = PasswordConfig(arguments: CommandLine.arguments)

    if config.showHelp {
        showHelp()
        return 0
    }

    if config.showTests {
        runBasicTests()
        return 0
    }

    if config.checkUpdate {
        return checkForUpdate()
    }

    // Analyze mode: score any input string
    if let input = config.analyzeString {
        print(lolcatArt)
        print("Meow Analyzing your string for cat-cracking resistance...")
        print("")
        let (score, analysis) = analyzeComplexity(of: input)
        print(analysis)
        print("")
        print(analyzeVerdict(for: score))
        return 0
    }

    // Load cat names (now from embedded data)
    let catNames = loadCatNames()
    guard !catNames.isEmpty else {
        FileHandle.standardError.write("ERROR: No cat names loaded from embedded data.\n".data(using: .utf8)!)
        return 1
    }

    // Silent mode: generate, copy best to clipboard, print nothing sensitive
    if config.psssst {
        var candidates: [(password: String, score: Double)] = []
        for _ in 1...5 {
            let password = generateSecurePassword(from: catNames, config: config)
            let (score, _) = analyzeComplexity(of: password)
            candidates.append((password, score))
        }
        guard let best = candidates.max(by: { $0.score < $1.score }) else {
            FileHandle.standardError.write("ERROR: Could not meow select best password\n".data(using: .utf8)!)
            return 1
        }
        if copyToClipboard(best.password) {
            print("----> copied!")
        } else {
            print(clipboardMissingHint())
            return 1
        }
        return 0
    }

    // Show ASCII art and title
    print(lolcatArt)
    print("Meow Password - Cat Name Based Secure Password Generator")
    print("========================================================")

    print("Loaded \(catNames.count) meow cat names")
    print("Generating 5 secure password meow candidates...")
    print("Config: \(config.numNumbers) numbers, \(config.numSymbols) symbols, max meow length \(config.maxLength)")
    print("")

    // Generate 5 password candidates
    var candidates: [(password: String, score: Double, analysis: String)] = []

    for i in 1...5 {
        let password = generateSecurePassword(from: catNames, config: config)
        let (score, analysis) = analyzeComplexity(of: password)
        candidates.append((password, score, analysis))

        print("Candidate \(i): \(password)")
        print("   Meow Score: \(String(format: "%.2f", score))/10.0")
        print("")
    }

    // Select the most secure password
    guard let bestCandidate = candidates.max(by: { $0.score < $1.score }) else {
        print("ERROR: Could not meow select best password")
        return 1
    }

    print("MOST SECURE PASSWORD MEOW SELECTED:")
    print("Password: \(bestCandidate.password)")
    print("Final Meow Score: \(String(format: "%.2f", bestCandidate.score))/10.0")
    print("")
    print(bestCandidate.analysis)

    if config.copyToClipboard {
        print("")
        if copyToClipboard(bestCandidate.password) {
            print("Password copied to clipboard!")
        } else {
            print(clipboardMissingHint())
        }
    } else {
        print("")
        print("Use 'meowpass --copy' to copy password to clipboard")
    }

    return 0
}

// Run the program
exit(main())

