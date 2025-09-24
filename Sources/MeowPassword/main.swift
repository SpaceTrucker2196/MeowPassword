import Foundation
import ArgumentParser
import MeowPasswordCore

#if canImport(AppKit)
import AppKit
#endif

struct MeowPasswordCommand: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "meowpass",
        abstract: "🐾 Generate a secure, random password based on cat names using Kolmogorov complexity analysis"
    )
    
    @Flag(name: .long, help: "Copy password to clipboard (macOS only)")
    var copy: Bool = false
    
    @Flag(name: .long, help: "Show detailed analysis for all candidates")
    var verbose: Bool = false
    
    func run() throws {
        // Find the cat names file
        guard let catNamesPath = findCatNamesFile() else {
            print("❌ Could not find catNamesText.txt file")
            throw ExitCode.failure
        }
        
        // Load cat names
        guard let catNameLoader = CatNameLoader(from: catNamesPath) else {
            print("❌ Failed to load cat names from \(catNamesPath)")
            throw ExitCode.failure
        }
        
        print("🐱 Loaded \(catNameLoader.count) cat names")
        print("🔄 Generating 5 secure password candidates...\n")
        
        // Generate password candidates
        let generator = PasswordGenerator(catNameLoader: catNameLoader)
        let candidates = generator.generateCandidates(count: 5)
        
        // Display all candidates
        for (index, candidate) in candidates.enumerated() {
            print("🔐 Candidate \(index + 1): \(candidate.password)")
            print("   Complexity Score: \(String(format: "%.2f", candidate.complexity.score))/10.0")
            
            if verbose {
                print("\(candidate.complexity.analysis)")
            }
            print()
        }
        
        // Select the most secure password
        guard let mostSecure = generator.selectMostSecure(from: candidates) else {
            print("❌ Failed to select most secure password")
            throw ExitCode.failure
        }
        
        print("🏆 Most Secure Password Selected:")
        print("🔐 \(mostSecure.password)")
        print("📊 Final Complexity Score: \(String(format: "%.2f", mostSecure.complexity.score))/10.0")
        print("\n\(mostSecure.complexity.analysis)")
        
        // Copy to clipboard if requested
        if copy {
            #if canImport(AppKit)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(mostSecure.password, forType: .string)
            print("\n📋 Password copied to clipboard!")
            #else
            print("\n❌ Clipboard functionality is only available on macOS")
            #endif
        } else {
            print("\n💡 Use --copy flag to copy password to clipboard")
        }
    }
    
    private func findCatNamesFile() -> String? {
        // Try multiple locations for the cat names file
        let possiblePaths = [
            // In the same directory as executable
            "./catNamesText.txt",
            // In the source directory
            "./Sources/MeowPassword/catNamesText.txt",
            // In the parent directory
            "../catNamesText.txt",
            // In the current working directory
            "catNamesText.txt"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return nil
    }
}

MeowPasswordCommand.main()