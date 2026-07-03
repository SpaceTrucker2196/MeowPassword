import Foundation

/// Result of a single `meowpass` invocation in "normal" mode.
struct MeowResult {
    var candidates: [(password: String, score: Double)]
    var best: String
    var bestScore: Double
    var analysis: String
    var rawOutput: String
}

enum MeowError: Error, LocalizedError {
    case binaryNotFound
    case nonZeroExit(Int32, String)
    case parseFailed(String)

    var errorDescription: String? {
        switch self {
        case .binaryNotFound:
            return "Could not locate the meowpass binary. Install it via Homebrew or add it to /usr/local/bin."
        case .nonZeroExit(let code, let output):
            return "meowpass exited with status \(code):\n\(output)"
        case .parseFailed(let output):
            return "Failed to parse meowpass output:\n\(output)"
        }
    }
}

/// Wraps the `meowpass` command-line tool. Looks for the binary in the app
/// bundle first, then falls back to well-known install locations.
enum MeowRunner {

    /// Resolve the path to the `meowpass` CLI. Bundled copy wins; then
    /// `/usr/local/bin`, `/opt/homebrew/bin`, then a `command -v` lookup.
    static func binaryURL() -> URL? {
        if let bundled = Bundle.main.url(forAuxiliaryExecutable: "meowpass") {
            return bundled
        }
        let candidates = [
            "/usr/local/bin/meowpass",
            "/opt/homebrew/bin/meowpass"
        ]
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        if let resolved = commandV("meowpass") {
            return URL(fileURLWithPath: resolved)
        }
        return nil
    }

    private static func commandV(_ name: String) -> String? {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "command -v \(name)"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle(forWritingAtPath: "/dev/null")
        do { try task.run() } catch { return nil }
        task.waitUntilExit()
        guard task.terminationStatus == 0 else { return nil }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let s = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return s.isEmpty ? nil : s
    }

    /// Run the CLI with the given arguments and capture stdout.
    @discardableResult
    static func run(arguments: [String]) throws -> String {
        guard let url = binaryURL() else { throw MeowError.binaryNotFound }
        let task = Process()
        task.executableURL = url
        task.arguments = arguments
        let out = Pipe()
        task.standardOutput = out
        task.standardError = out
        try task.run()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()
        let output = String(data: data, encoding: .utf8) ?? ""
        if task.terminationStatus != 0 {
            throw MeowError.nonZeroExit(task.terminationStatus, output)
        }
        return output
    }

    /// Generate a password, parsing the CLI output into a structured result.
    static func generate(numbers: Int, symbols: Int, maxLength: Int) throws -> MeowResult {
        let output = try run(arguments: [
            "--numbers", String(numbers),
            "--symbols", String(symbols),
            "--max-length", String(maxLength)
        ])
        return try parseGenerateOutput(output)
    }

    /// Silent generate: use `--psssst` so the CLI copies the winner and prints nothing sensitive.
    /// Returns the best password by re-running non-silently for display, or the copied indicator.
    static func generateSilent(numbers: Int, symbols: Int, maxLength: Int) throws -> String {
        return try run(arguments: [
            "--psssst",
            "--numbers", String(numbers),
            "--symbols", String(symbols),
            "--max-length", String(maxLength)
        ])
    }

    /// Analyze an arbitrary string.
    static func analyze(_ input: String) throws -> String {
        return try run(arguments: ["--analyze", input])
    }

    // MARK: - Parsing

    static func parseGenerateOutput(_ output: String) throws -> MeowResult {
        var candidates: [(String, Double)] = []
        var best: String?
        var bestScore: Double = 0
        var analysisLines: [String] = []
        var inAnalysis = false

        let lines = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var i = 0
        while i < lines.count {
            let line = lines[i]
            if line.hasPrefix("Candidate ") {
                if let colon = line.firstIndex(of: ":") {
                    let pw = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
                    var score: Double = 0
                    if i + 1 < lines.count {
                        score = parseScore(from: lines[i + 1]) ?? 0
                    }
                    candidates.append((pw, score))
                }
            } else if line.hasPrefix("Password: ") && best == nil && line.range(of: "MOST SECURE") == nil {
                // Skip; we want the "MOST SECURE" section only.
            } else if line.contains("MOST SECURE PASSWORD") {
                if i + 1 < lines.count, lines[i + 1].hasPrefix("Password: ") {
                    best = String(lines[i + 1].dropFirst("Password: ".count))
                }
                if i + 2 < lines.count {
                    bestScore = parseScore(from: lines[i + 2]) ?? 0
                }
            } else if line.contains("Meow Complexity Analysis") {
                inAnalysis = true
                analysisLines.append(line)
            } else if inAnalysis {
                analysisLines.append(line)
                if line.contains("Overall Relavency") { inAnalysis = false }
            }
            i += 1
        }

        guard let winner = best else {
            throw MeowError.parseFailed(output)
        }

        return MeowResult(
            candidates: candidates,
            best: winner,
            bestScore: bestScore,
            analysis: analysisLines.joined(separator: "\n"),
            rawOutput: output
        )
    }

    private static func parseScore(from line: String) -> Double? {
        // Matches lines like "   Meow Score: 1.63/10.0" or "Final Meow Score: 1.67/10.0"
        guard let colon = line.firstIndex(of: ":") else { return nil }
        let rest = line[line.index(after: colon)...]
            .replacingOccurrences(of: "/10.0", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(rest)
    }
}
