// Sources/MeowPassCore/MeowPassCore.swift
//
// Platform-independent MeowPassword logic: cat-name-based password generation,
// Kolmogorov-style complexity analysis, and the voice-friendly "meow key"
// passphrase. Extracted from the CLI so the CLI, the macOS app, and the iOS app
// share one implementation instead of the app shelling out to the CLI.

import Foundation

// MARK: - Configuration

/// Generation parameters. (The CLI keeps its own argument parsing and builds
/// one of these; the apps build it from their sliders.)
public struct PasswordConfig {
    public var numNumbers: Int   // random numbers to insert (1-10)
    public var numSymbols: Int   // symbols replacing letters (1-10)
    public var maxLength: Int    // max password length (15-50)

    public init(numNumbers: Int = 2, numSymbols: Int = 2, maxLength: Int = 25) {
        self.numNumbers = numNumbers
        self.numSymbols = numSymbols
        self.maxLength = maxLength
    }
}

/// A generated password with its complexity score and human-readable analysis.
public struct Candidate: Identifiable {
    public let id = UUID()
    public let password: String
    public let score: Double
    public let analysis: String
    public init(password: String, score: Double, analysis: String) {
        self.password = password
        self.score = score
        self.analysis = analysis
    }
}

// MARK: - Public API

public enum MeowPass {

    /// The embedded cat-name database (~1000 names).
    public static func catNames() -> [String] { embeddedCatNames }

    /// Generate `count` candidate passwords, scored.
    public static func generate(config: PasswordConfig, count: Int = 5) -> [Candidate] {
        let names = catNames()
        return (0..<max(1, count)).map { _ in
            let pw = generateSecurePassword(from: names, config: config)
            let (score, analysis) = analyzeComplexity(of: pw)
            return Candidate(password: pw, score: score, analysis: analysis)
        }
    }

    /// Generate candidates and return the highest-scoring one.
    public static func best(config: PasswordConfig, count: Int = 5) -> Candidate {
        let candidates = generate(config: config, count: count)
        return candidates.max(by: { $0.score < $1.score }) ?? candidates[0]
    }

    /// Score an arbitrary string and return its analysis + a catified verdict.
    public static func analyze(_ input: String) -> (score: Double, analysis: String, verdict: String) {
        let (score, analysis) = analyzeComplexity(of: input)
        return (score, analysis, analyzeVerdict(for: score))
    }

    /// A voice-friendly `catname-catname-catname` passphrase from short,
    /// purely-alphabetic ASCII names — easy to read aloud over the phone.
    public static func meowKey(words: Int = 3, maxLen: Int = 5) -> String {
        let w = max(2, min(6, words))
        let m = max(3, min(8, maxLen))
        let pool = Set(catNames().compactMap { name -> String? in
            let lower = name.lowercased()
            guard lower.count >= 2, lower.count <= m,
                  lower.allSatisfy({ $0.isLetter && $0.isASCII }) else { return nil }
            return lower
        })
        guard pool.count >= w else { return "tom-max-luna" }
        return Array(pool).shuffled().prefix(w).joined(separator: "-")
    }
}

// MARK: - Cat name selection

func selectRandomCatNames(from catNames: [String], count: Int) -> [String] {
    guard !catNames.isEmpty, count > 0 else { return [] }
    return Array(catNames.shuffled().prefix(min(count, catNames.count)))
}

func createBasePhrase(from catNames: [String], maxLength: Int) -> String {
    let joinedNames = catNames.joined()
    if joinedNames.count < 15 {
        let additionalNames = selectRandomCatNames(from: catNames, count: 5)
        let extended = joinedNames + additionalNames.joined()
        return String(extended.prefix(maxLength))
    } else if joinedNames.count > maxLength {
        return String(joinedNames.prefix(maxLength))
    }
    return joinedNames
}

// MARK: - Security transformations

func randomlyCapitalizeLetters(in password: inout [Character], count: Int) {
    let letterIndices = password.enumerated().compactMap { $0.element.isLetter ? $0.offset : nil }
    for index in Array(letterIndices.shuffled().prefix(count)) {
        password[index] = Character(password[index].uppercased())
    }
}

func insertRandomNumbers(into password: inout [Character], count: Int) {
    let numbers = "0123456789"
    for _ in 0..<count {
        password.insert(numbers.randomElement()!, at: Int.random(in: 0...password.count))
    }
}

func replaceLettersWithSymbols(in password: inout [Character], count: Int) {
    let symbols = "!@#$%^&*()-_=+[]{;:.<>?"
    let letterIndices = password.enumerated().compactMap { $0.element.isLetter ? $0.offset : nil }
    for index in Array(letterIndices.shuffled().prefix(count)) {
        password[index] = symbols.randomElement()!
    }
}

// MARK: - Password generation

func generateSecurePassword(from catNames: [String], config: PasswordConfig) -> String {
    let nameCount = Int.random(in: 2...6)
    let selectedNames = selectRandomCatNames(from: catNames, count: nameCount)
    let basePhrase = createBasePhrase(from: selectedNames, maxLength: config.maxLength)
    var password = Array(basePhrase.lowercased().replacingOccurrences(of: " ", with: ""))

    randomlyCapitalizeLetters(in: &password, count: 3)
    insertRandomNumbers(into: &password, count: config.numNumbers)
    replaceLettersWithSymbols(in: &password, count: config.numSymbols)

    if password.count > config.maxLength {
        password = Array(password.prefix(config.maxLength))
    }
    return String(password)
}

// MARK: - Complexity analysis

func calculateShannonEntropy(of string: String) -> Double {
    let charCounts = string.reduce(into: [Character: Int]()) { $0[$1, default: 0] += 1 }
    let length = Double(string.count)
    return charCounts.values.reduce(0.0) { result, count in
        let p = Double(count) / length
        return result - (p * log2(p))
    }
}

func calculateCompressionRatio(of string: String) -> Double {
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

func getSubstrings(from string: String, maxLength: Int) -> [String] {
    let chars = Array(string)
    var substrings: [String] = []
    guard chars.count >= 2 else { return substrings }
    for length in 2...min(maxLength, chars.count) {
        for start in 0...(chars.count - length) {
            substrings.append(String(chars[start..<start + length]))
        }
    }
    return substrings
}

func calculatePatternComplexity(of string: String) -> Double {
    let substrings = getSubstrings(from: string, maxLength: 4)
    guard !substrings.isEmpty else { return 0.0 }
    return Double(Set(substrings).count) / Double(substrings.count)
}

func calculateCharacterDiversity(of string: String) -> Double {
    let uniqueChars = Set(string)
    let categories = [
        uniqueChars.contains { $0.isLowercase },
        uniqueChars.contains { $0.isUppercase },
        uniqueChars.contains { $0.isNumber },
        uniqueChars.contains { !$0.isLetter && !$0.isNumber }
    ].filter { $0 }.count
    return Double(categories) / 4.0
}

func analyzeComplexity(of password: String) -> (score: Double, analysis: String) {
    let entropy = calculateShannonEntropy(of: password)
    let compressionRatio = calculateCompressionRatio(of: password)
    let patternComplexity = calculatePatternComplexity(of: password)
    let diversity = calculateCharacterDiversity(of: password)

    let entropyN     = min(entropy / 4.5, 1.0)
    let compressionN = max(min(compressionRatio, 1.0), 0.0)
    let patternN     = patternComplexity
    let diversityN   = diversity
    let lengthN      = min(Double(password.count) / 25.0, 1.0)

    let unit = (entropyN * 0.30) + (compressionN * 0.10) + (patternN * 0.25)
             + (diversityN * 0.25) + (lengthN * 0.10)
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

/// A catified verdict line for a given complexity score. Higher = better.
public func analyzeVerdict(for score: Double) -> String {
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
