import Foundation
import SwiftUI
import AppKit

/// Observable state for the main window and menu bar UI.
@MainActor
final class GenerationModel: ObservableObject {
    @Published var numbers: Int = 3
    @Published var symbols: Int = 2
    @Published var maxLength: Int = 25
    @Published var analyzeInput: String = ""

    @Published var candidates: [Candidate] = []
    @Published var bestPassword: String = ""
    @Published var bestScore: Double = 0
    @Published var analysisText: String = ""
    @Published var analyzeResult: String = ""

    @Published var isBusy: Bool = false
    @Published var lastError: String?

    struct Candidate: Identifiable {
        let id = UUID()
        let password: String
        let score: Double
    }

    func generate() {
        let n = numbers, s = symbols, m = maxLength
        runOffMain(
            work: { try MeowRunner.generate(numbers: n, symbols: s, maxLength: m) },
            apply: { result in
                self.applyResult(result)
            }
        )
    }

    /// One-shot: generate + copy best to clipboard.
    func generateAndCopy() {
        let n = numbers, s = symbols, m = maxLength
        runOffMain(
            work: { try MeowRunner.generate(numbers: n, symbols: s, maxLength: m) },
            apply: { result in
                self.applyResult(result)
                Clipboard.copy(result.best)
            }
        )
    }

    func analyze() {
        let input = analyzeInput
        guard !input.isEmpty else { return }
        runOffMain(
            work: { try MeowRunner.analyze(input) },
            apply: { output in
                self.analyzeResult = output
            }
        )
    }

    func copyBest() {
        guard !bestPassword.isEmpty else { return }
        Clipboard.copy(bestPassword)
    }

    // MARK: - Internals

    private func applyResult(_ result: MeowResult) {
        self.candidates = result.candidates.map { Candidate(password: $0.password, score: $0.score) }
        self.bestPassword = result.best
        self.bestScore = result.bestScore
        self.analysisText = result.analysis
    }

    /// Run `work` on a background queue, then invoke `apply` on the main
    /// actor with the result. All `@Published` writes stay on main.
    nonisolated private func runOffMain<T>(
        work: @escaping () throws -> T,
        apply: @escaping @MainActor (T) -> Void
    ) {
        Task { @MainActor in
            self.isBusy = true
            self.lastError = nil
        }
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let value = try work()
                Task { @MainActor in
                    apply(value)
                    self.isBusy = false
                }
            } catch {
                let message = error.localizedDescription
                Task { @MainActor in
                    self.lastError = message
                    self.isBusy = false
                }
            }
        }
    }
}

enum Clipboard {
    static func copy(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    static func read() -> String {
        NSPasteboard.general.string(forType: .string) ?? ""
    }
}
