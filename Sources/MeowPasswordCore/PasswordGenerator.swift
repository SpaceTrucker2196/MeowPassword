import Foundation

public struct PasswordCandidate {
    public let password: String
    public let complexity: KolmogorovComplexity
    
    public init(password: String, complexity: KolmogorovComplexity) {
        self.password = password
        self.complexity = complexity
    }
}

public class PasswordGenerator {
    private let catNameLoader: CatNameLoader
    private let symbols = "!@#$%^&*()-_=+[]{}|;:,.<>?"
    private let numbers = "0123456789"
    
    public init(catNameLoader: CatNameLoader) {
        self.catNameLoader = catNameLoader
    }
    
    public func generateSecurePassword() -> String {
        // Generate base phrase from 3-5 cat names (15-25 characters)
        let nameCount = Int.random(in: 3...5)
        let selectedNames = catNameLoader.randomNames(count: nameCount)
        
        // Join names and ensure length is 15-25 characters
        var basePhrase = selectedNames.joined()
        
        // Adjust length to be between 15-25 characters
        if basePhrase.count < 15 {
            // Add more names if too short
            let additionalNames = catNameLoader.randomNames(count: 2)
            basePhrase += additionalNames.joined()
        }
        
        // Truncate if still too long
        if basePhrase.count > 25 {
            basePhrase = String(basePhrase.prefix(25))
        }
        
        // Apply security transformations
        var securePassword = Array(basePhrase.lowercased())
        
        // 1. Randomly capitalize 3 letters
        applyRandomCapitalization(&securePassword, count: 3)
        
        // 2. Insert 3-5 random numbers
        let numberCount = Int.random(in: 3...5)
        insertRandomNumbers(&securePassword, count: numberCount)
        
        // 3. Replace 2 letters with symbols
        replaceWithRandomSymbols(&securePassword, count: 2)
        
        // 4. Remove repeating letters and replace with random digits
        removeRepeatingLetters(&securePassword)
        
        return String(securePassword)
    }
    
    public func generateCandidates(count: Int = 5) -> [PasswordCandidate] {
        var candidates: [PasswordCandidate] = []
        
        for _ in 0..<count {
            let password = generateSecurePassword()
            let complexity = KolmogorovComplexityAnalyzer.analyze(password)
            candidates.append(PasswordCandidate(password: password, complexity: complexity))
        }
        
        return candidates
    }
    
    public func selectMostSecure(from candidates: [PasswordCandidate]) -> PasswordCandidate? {
        return candidates.max { $0.complexity.score < $1.complexity.score }
    }
    
    private func applyRandomCapitalization(_ password: inout [Character], count: Int) {
        let letterIndices = password.enumerated().compactMap { index, char in
            char.isLetter ? index : nil
        }
        
        let indicesToCapitalize = Array(letterIndices.shuffled().prefix(count))
        
        for index in indicesToCapitalize {
            password[index] = Character(password[index].uppercased())
        }
    }
    
    private func insertRandomNumbers(_ password: inout [Character], count: Int) {
        for _ in 0..<count {
            let randomNumber = numbers.randomElement()!
            let insertIndex = Int.random(in: 0...password.count)
            password.insert(randomNumber, at: insertIndex)
        }
    }
    
    private func replaceWithRandomSymbols(_ password: inout [Character], count: Int) {
        let letterIndices = password.enumerated().compactMap { index, char in
            char.isLetter ? index : nil
        }
        
        let indicesToReplace = Array(letterIndices.shuffled().prefix(count))
        
        for index in indicesToReplace {
            password[index] = symbols.randomElement()!
        }
    }
    
    private func removeRepeatingLetters(_ password: inout [Character]) {
        var seen = Set<Character>()
        var previousChar: Character?
        
        for i in 0..<password.count {
            let currentChar = password[i].lowercased().first!
            
            if currentChar.isLetter {
                if let prev = previousChar, prev == currentChar || seen.contains(currentChar) {
                    password[i] = numbers.randomElement()!
                } else {
                    seen.insert(currentChar)
                }
                previousChar = currentChar
            }
        }
    }
}