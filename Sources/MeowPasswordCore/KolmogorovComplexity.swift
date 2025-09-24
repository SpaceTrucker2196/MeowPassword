import Foundation

public struct KolmogorovComplexity {
    public let score: Double
    public let analysis: String
    
    public init(score: Double, analysis: String) {
        self.score = score
        self.analysis = analysis
    }
}

public class KolmogorovComplexityAnalyzer {
    
    public static func analyze(_ input: String) -> KolmogorovComplexity {
        let analysis = generateVerboseAnalysis(input)
        let score = calculateComplexityScore(input)
        
        return KolmogorovComplexity(score: score, analysis: analysis)
    }
    
    private static func calculateComplexityScore(_ input: String) -> Double {
        guard !input.isEmpty else { return 0.0 }
        
        var score: Double = 0.0
        
        // 1. Entropy-based complexity (character distribution)
        let entropy = calculateShannonEntropy(input)
        score += entropy * 0.3
        
        // 2. Compression ratio (approximation of Kolmogorov complexity)
        let compressionRatio = calculateCompressionRatio(input)
        score += compressionRatio * 0.25
        
        // 3. Pattern complexity (repetition analysis)
        let patternComplexity = calculatePatternComplexity(input)
        score += patternComplexity * 0.2
        
        // 4. Character set diversity
        let diversity = calculateCharacterSetDiversity(input)
        score += diversity * 0.15
        
        // 5. Length normalization
        let lengthScore = min(Double(input.count) / 25.0, 1.0)
        score += lengthScore * 0.1
        
        return min(score, 10.0) // Cap at 10.0
    }
    
    private static func calculateShannonEntropy(_ input: String) -> Double {
        let charCounts = input.reduce(into: [Character: Int]()) { counts, char in
            counts[char, default: 0] += 1
        }
        
        let length = Double(input.count)
        let entropy = charCounts.values.reduce(0.0) { result, count in
            let probability = Double(count) / length
            return result - (probability * log2(probability))
        }
        
        return entropy
    }
    
    private static func calculateCompressionRatio(_ input: String) -> Double {
        // Simple approximation using run-length encoding efficiency
        var compressed = 0
        var previous: Character?
        var runLength = 1
        
        for char in input {
            if char == previous {
                runLength += 1
            } else {
                compressed += runLength > 1 ? 2 : 1 // 2 bytes for runs, 1 for singles
                runLength = 1
                previous = char
            }
        }
        compressed += runLength > 1 ? 2 : 1
        
        return 1.0 - (Double(compressed) / Double(input.count))
    }
    
    private static func calculatePatternComplexity(_ input: String) -> Double {
        let substrings = generateSubstrings(input, maxLength: 4)
        let uniqueSubstrings = Set(substrings)
        
        if substrings.isEmpty { return 0.0 }
        
        return Double(uniqueSubstrings.count) / Double(substrings.count)
    }
    
    private static func calculateCharacterSetDiversity(_ input: String) -> Double {
        let uniqueChars = Set(input)
        let hasLower = uniqueChars.contains { $0.isLowercase }
        let hasUpper = uniqueChars.contains { $0.isUppercase }
        let hasDigits = uniqueChars.contains { $0.isNumber }
        let hasSymbols = uniqueChars.contains { !$0.isLetter && !$0.isNumber }
        
        let categories = [hasLower, hasUpper, hasDigits, hasSymbols].filter { $0 }.count
        return Double(categories) / 4.0
    }
    
    private static func generateSubstrings(_ input: String, maxLength: Int) -> [String] {
        let chars = Array(input)
        var substrings: [String] = []
        
        for length in 2...min(maxLength, chars.count) {
            for start in 0...(chars.count - length) {
                let substring = String(chars[start..<start + length])
                substrings.append(substring)
            }
        }
        
        return substrings
    }
    
    private static func generateVerboseAnalysis(_ input: String) -> String {
        let entropy = calculateShannonEntropy(input)
        let compressionRatio = calculateCompressionRatio(input)
        let patternComplexity = calculatePatternComplexity(input)
        let diversity = calculateCharacterSetDiversity(input)
        let finalScore = calculateComplexityScore(input)
        
        let uniqueChars = Set(input)
        let hasLower = uniqueChars.contains { $0.isLowercase }
        let hasUpper = uniqueChars.contains { $0.isUppercase }
        let hasDigits = uniqueChars.contains { $0.isNumber }
        let hasSymbols = uniqueChars.contains { !$0.isLetter && !$0.isNumber }
        
        var analysis = """
        🔍 Kolmogorov Complexity Analysis:
        
        📊 Overall Complexity Score: \(String(format: "%.2f", finalScore))/10.0
        
        📈 Component Analysis:
        • Shannon Entropy: \(String(format: "%.3f", entropy)) bits
        • Compression Resistance: \(String(format: "%.1f", compressionRatio * 100))%
        • Pattern Uniqueness: \(String(format: "%.1f", patternComplexity * 100))%
        • Character Diversity: \(String(format: "%.1f", diversity * 100))%
        
        🎯 Character Composition:
        • Length: \(input.count) characters
        • Unique Characters: \(uniqueChars.count)
        • Lowercase Letters: \(hasLower ? "✅" : "❌")
        • Uppercase Letters: \(hasUpper ? "✅" : "❌")
        • Digits: \(hasDigits ? "✅" : "❌")
        • Symbols: \(hasSymbols ? "✅" : "❌")
        
        💡 Complexity Interpretation:
        """
        
        switch finalScore {
        case 0..<2:
            analysis += "Very Low - Highly predictable pattern"
        case 2..<4:
            analysis += "Low - Some predictable elements"
        case 4..<6:
            analysis += "Moderate - Reasonably complex"
        case 6..<8:
            analysis += "High - Strong complexity"
        case 8...10:
            analysis += "Very High - Excellent randomness and complexity"
        default:
            analysis += "Score out of range"
        }
        
        return analysis
    }
}