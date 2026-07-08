import Foundation
import SwiftUI
import AppKit
import MeowPassCore

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
    @Published var isAnalyzing: Bool = false
    @Published var lastError: String?

    struct Candidate: Identifiable {
        let id = UUID()
        let password: String
        let score: Double
    }

    private func config() -> PasswordConfig {
        PasswordConfig(numNumbers: numbers, numSymbols: symbols, maxLength: maxLength)
    }

    func generate() {
        let cfg = config()
        runOffMain(
            work: { MeowPass.generate(config: cfg, count: 5) },
            apply: { candidates in self.applyResult(candidates) }
        )
    }

    /// One-shot: generate + copy best to clipboard.
    func generateAndCopy() {
        let cfg = config()
        runOffMain(
            work: { MeowPass.generate(config: cfg, count: 5) },
            apply: { candidates in
                self.applyResult(candidates)
                Clipboard.copy(self.bestPassword)
            }
        )
    }

    func analyze() {
        let input = analyzeInput
        guard !input.isEmpty else { return }
        isAnalyzing = true
        analyzeResult = ""
        lastError = nil
        Task {
            async let minShow: Void = Task.sleep(nanoseconds: 1_100_000_000)  // let the animation land
            let result = await Task.detached { MeowPass.analyze(input) }.value
            try? await minShow
            self.analyzeResult = result.analysis + "\n\n" + result.verdict
            self.isAnalyzing = false
        }
    }

    func copyBest() {
        guard !bestPassword.isEmpty else { return }
        Clipboard.copy(bestPassword)
    }

    // MARK: - Internals

    private func applyResult(_ coreCandidates: [MeowPassCore.Candidate]) {
        self.candidates = coreCandidates.map { Candidate(password: $0.password, score: $0.score) }
        let best = coreCandidates.max(by: { $0.score < $1.score })
        self.bestPassword = best?.password ?? ""
        self.bestScore = best?.score ?? 0
        self.analysisText = best?.analysis ?? ""
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
