import SwiftUI

/// Reference of every feature the app and CLI expose. Opened via
/// Help → MeowPassword Help (⌘?).
struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                section("What it does") {
                    para("MeowPassword builds phrase-style passwords from a pool of cat names, sprinkles in digits and symbols, scores five candidates using entropy, pattern uniqueness, character diversity, and length, then hands you the strongest one. Higher score = harder to crack.")
                }

                section("Main window") {
                    row("Generate", "⌘G", "Produce five candidates and show the best one along with its complexity breakdown.")
                    row("Generate + Copy", "⇧⌘C", "Generate and copy the best password to the clipboard in one step.")
                    row("Copy Best", "⌘B", "Re-copy the currently displayed best password.")
                    row("Analyze", "—", "Paste a string into the JUDGE panel to score it as if it were a password.")
                    row("RULES sliders", "—", "Tune the number of digits, symbols, and the maximum length (all clamped to safe ranges).")
                }

                section("Menu bar (cat icon in the top-right)") {
                    row("★ GENERATE + COPY!", "⌘G", "One-click generate + copy from anywhere. No need to open the main window.")
                    row("Generate", "—", "Generate a set of candidates and open the main window.")
                    row("Copy Best", "⌘C", "Re-copy the current winner.")
                    row("Open MeowPassword…", "—", "Bring the main window to front.")
                    row("Quit", "⌘Q", "Exit the app.")
                }

                section("Shortcuts and Spotlight (App Intents)") {
                    para("These intents are auto-registered when the app launches. Look for them in the Shortcuts app or type any of the trigger phrases into Spotlight.")
                    row("Generate + Copy MeowPassword", "—", "\"Generate a MeowPassword\", \"New MeowPassword\"")
                    row("Generate MeowPassword", "—", "\"Generate a MeowPassword\" (accepts numbers, symbols, max length, copy-to-clipboard toggle as parameters)")
                    row("Analyze Password", "—", "\"Analyze password with MeowPassword\" — accepts any string and returns the catified analysis.")
                }

                section("Services menu (right-click any selected text)") {
                    row("Insert MeowPassword", "—", "Replaces the selection with a fresh password.")
                    row("Analyze with MeowPassword", "—", "Replaces the selection with the complexity analysis for that string.")
                }

                section("URL scheme (for Alfred, Raycast, LaunchBar, etc.)") {
                    row("meowpass://generate", "—", "Open the app and generate a fresh set of candidates.")
                    row("meowpass://copy", "—", "Generate silently and drop the winner on the clipboard.")
                }

                section("Command-line interface (`meowpass`)") {
                    para("The `meowpass` binary lives inside the app bundle and is also installable via `brew install SpaceTrucker2196/meowpassword/meowpass`. Every menu action above maps to a CLI flag.")
                    row("--numbers N", "—", "Digits to insert (1–10, default 1–4).")
                    row("--symbols N", "—", "Symbol substitutions (1–10, default 2).")
                    row("--max-length N", "—", "Max password length (15–50, default 25).")
                    row("--copy", "—", "Copy the winner to the clipboard (pbcopy / xclip / wl-copy).")
                    row("--psssst, -p", "—", "Silent copy — generate, copy, print nothing sensitive.")
                    row("--analyze, -a S", "—", "Score an existing string instead of generating.")
                    row("--update", "—", "Check GitHub for a newer release and offer to install it.")
                    row("--test", "—", "Run the bundled test suite.")
                    row("--help, -h", "—", "Print CLI help.")
                }

                section("Complexity metrics") {
                    row("Ball of Yarn Entropy", "—", "Shannon entropy in bits per character. Higher = less predictable.")
                    row("Mashing Resistance", "—", "Run-length compression ratio. Higher = less repetitive.")
                    row("Shiny Foil Ball Uniqueness", "—", "Fraction of unique 2–4 char substrings. Higher = fewer repeated motifs.")
                    row("Organic NonGMO Catnip", "—", "Coverage of lower / upper / digit / symbol categories.")
                    row("Overall Relavency", "—", "Weighted composite, 0–10. 0–3 hiss, 3–5 too easy, 5–7 not bad, 7+ purrfect.")
                }

                section("Learn more") {
                    Link("Project on GitHub",
                         destination: URL(string: "https://github.com/SpaceTrucker2196/MeowPassword")!)
                    Link("Report an issue",
                         destination: URL(string: "https://github.com/SpaceTrucker2196/MeowPassword/issues")!)
                }

                Spacer(minLength: 0)
            }
            .padding(22)
        }
        .frame(minWidth: 540, minHeight: 620)
    }

    // MARK: - Building blocks

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.title3, design: .rounded).weight(.heavy))
            content()
        }
    }

    private func row(_ name: String, _ shortcut: String, _ desc: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(.body, design: .monospaced).weight(.semibold))
                if shortcut != "—" {
                    Text(shortcut)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 200, alignment: .leading)

            Text(desc)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func para(_ text: String) -> some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
