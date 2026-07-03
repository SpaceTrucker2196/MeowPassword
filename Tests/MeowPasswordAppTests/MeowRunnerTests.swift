import XCTest
@testable import MeowPasswordApp

/// Tests for `MeowRunner` — mostly the parser, since the shell-out
/// itself needs the actual `meowpass` binary and gets exercised in the
/// integration tests further down.
final class MeowRunnerTests: XCTestCase {

    // MARK: - Parser

    func testParseFullCLIOutput() throws {
        let sample = """
        Loaded 1000 meow cat names
        Generating 5 secure password meow candidates...
        Config: 3 numbers, 2 symbols, max meow length 25

        Candidate 1: aB2c#Def4gHijk
           Meow Score: 8.11/10.0

        Candidate 2: xy1Z@wErtY7uio
           Meow Score: 7.90/10.0

        Candidate 3: fluff_5Yba11m#o
           Meow Score: 8.42/10.0

        Candidate 4: paW3ln.k9jhg
           Meow Score: 6.75/10.0

        Candidate 5: R0oxq$le6nfoP
           Meow Score: 8.03/10.0

        MOST SECURE PASSWORD MEOW SELECTED:
        Password: fluff_5Yba11m#o
        Final Meow Score: 8.42/10.0

        Meow Complexity Analysis:
        - Password: fluff_5Yba11m#o
        - Tail Size: 15 cm
        - Ball of Yarn Entropy: 3.500 bits
        - Overall Relavency: 8.42/10.0

        Use 'meowpass --copy' to copy password to clipboard
        """

        let result = try MeowRunner.parseGenerateOutput(sample)

        XCTAssertEqual(result.candidates.count, 5)
        XCTAssertEqual(result.candidates[0].password, "aB2c#Def4gHijk")
        XCTAssertEqual(result.candidates[0].score, 8.11, accuracy: 0.001)
        XCTAssertEqual(result.candidates[4].password, "R0oxq$le6nfoP")
        XCTAssertEqual(result.candidates[4].score, 8.03, accuracy: 0.001)

        XCTAssertEqual(result.best, "fluff_5Yba11m#o")
        XCTAssertEqual(result.bestScore, 8.42, accuracy: 0.001)

        XCTAssertTrue(result.analysis.contains("Meow Complexity Analysis"))
        XCTAssertTrue(result.analysis.contains("Overall Relavency"))
    }

    func testParseFailsWithoutBestSection() {
        let sample = """
        Candidate 1: hello
           Meow Score: 1.00/10.0
        """

        XCTAssertThrowsError(try MeowRunner.parseGenerateOutput(sample)) { err in
            guard case MeowError.parseFailed = err else {
                return XCTFail("expected .parseFailed, got \(err)")
            }
        }
    }

    func testParseHandlesEmptyCandidates() throws {
        let sample = """
        MOST SECURE PASSWORD MEOW SELECTED:
        Password: onlyOne#7
        Final Meow Score: 5.55/10.0
        """

        let result = try MeowRunner.parseGenerateOutput(sample)
        XCTAssertEqual(result.candidates.count, 0)
        XCTAssertEqual(result.best, "onlyOne#7")
        XCTAssertEqual(result.bestScore, 5.55, accuracy: 0.001)
    }

    // MARK: - Binary lookup

    func testBinaryURLReturnsSomethingOnDevMachine() {
        // Should either find the binary via bundle, /usr/local/bin, /opt/homebrew/bin,
        // or `command -v`. On a CI runner without meowpass installed, this may return nil.
        // Either way it must not crash.
        let url = MeowRunner.binaryURL()
        if let url {
            XCTAssertTrue(FileManager.default.isExecutableFile(atPath: url.path),
                          "\(url.path) is not executable")
        }
    }

    // MARK: - End-to-end (only runs if a real meowpass is on PATH)

    func testGenerateEndToEndIfBinaryAvailable() throws {
        guard MeowRunner.binaryURL() != nil else {
            throw XCTSkip("meowpass binary not available in this environment")
        }
        let result = try MeowRunner.generate(numbers: 3, symbols: 2, maxLength: 25)
        XCTAssertFalse(result.best.isEmpty)
        XCTAssertGreaterThan(result.candidates.count, 0)
        XCTAssertGreaterThan(result.bestScore, 0)
        XCTAssertLessThanOrEqual(result.bestScore, 10)
    }
}
