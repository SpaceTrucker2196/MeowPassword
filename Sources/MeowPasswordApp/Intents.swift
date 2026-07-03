import AppIntents
import AppKit

/// "Generate a MeowPassword" — available in Shortcuts, Spotlight, and via Siri.
struct GenerateMeowPasswordIntent: AppIntent {
    static var title: LocalizedStringResource = "Generate MeowPassword"
    static var description: IntentDescription =
        "Generate a secure cat-name-based password."
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Numbers", default: 3)
    var numbers: Int

    @Parameter(title: "Symbols", default: 2)
    var symbols: Int

    @Parameter(title: "Maximum length", default: 25)
    var maxLength: Int

    @Parameter(title: "Copy to clipboard", default: true)
    var copyToClipboard: Bool

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let result = try MeowRunner.generate(
            numbers: numbers, symbols: symbols, maxLength: maxLength
        )
        if copyToClipboard {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(result.best, forType: .string)
        }
        return .result(
            value: result.best,
            dialog: IntentDialog("Purrfect. Score \(String(format: "%.2f", result.bestScore))/10.")
        )
    }
}

/// "Analyze Password" — accepts a string and returns the catified analysis.
struct AnalyzePasswordIntent: AppIntent {
    static var title: LocalizedStringResource = "Analyze Password"
    static var description: IntentDescription =
        "Score a password using MeowPassword's complexity heuristics."
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Password", inputConnectionBehavior: .connectToPreviousIntentResult)
    var input: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let output = try MeowRunner.analyze(input)
        return .result(value: output)
    }
}

/// Silent generate → copy → return the copied password (also useful when
/// piping into other Shortcuts actions).
struct GenerateAndCopyIntent: AppIntent {
    static var title: LocalizedStringResource = "Generate + Copy MeowPassword"
    static var description: IntentDescription =
        "Generate a secure password and copy it to the clipboard."
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let result = try MeowRunner.generate(numbers: 3, symbols: 2, maxLength: 25)
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(result.best, forType: .string)
        return .result(dialog: IntentDialog("Copied. Meow."))
    }
}

/// Surfaces the three intents to Shortcuts and Spotlight without the user
/// having to hand-build a shortcut first.
struct MeowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GenerateAndCopyIntent(),
            phrases: [
                "Generate a \(.applicationName) password",
                "New \(.applicationName)"
            ],
            shortTitle: "Generate + Copy",
            systemImageName: "cat.fill"
        )
        AppShortcut(
            intent: GenerateMeowPasswordIntent(),
            phrases: [
                "Generate a \(.applicationName)"
            ],
            shortTitle: "Generate",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: AnalyzePasswordIntent(),
            phrases: [
                "Analyze password with \(.applicationName)"
            ],
            shortTitle: "Analyze",
            systemImageName: "magnifyingglass"
        )
    }
}
