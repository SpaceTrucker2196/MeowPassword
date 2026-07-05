import SwiftUI
import AppKit

@main
struct MeowPasswordApp: App {
    @StateObject private var model = GenerationModel()
    @StateObject private var meowGramModel = MeowGramModel()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup("MeowPassword", id: "main") {
            ContentView()
                .environmentObject(model)
                .onAppear { appDelegate.model = model }
                .onOpenURL { url in handleURL(url) }
        }
        .defaultSize(width: 500, height: 640)
        .windowResizability(.contentMinSize)
        .commands {
            // MARK: App menu (About)
            CommandGroup(replacing: .appInfo) {
                Button("About MeowPassword") { showAboutPanel() }
            }

            // MARK: File → replaced with password actions
            CommandGroup(replacing: .newItem) {
                Button("Generate Password") { model.generate() }
                    .keyboardShortcut("g", modifiers: [.command])

                Button("Generate + Copy") { model.generateAndCopy() }
                    .keyboardShortcut("c", modifiers: [.command, .shift])

                MeowGramMenuItem()

                Divider()

                Button("Copy Best Password") { model.copyBest() }
                    .keyboardShortcut("b", modifiers: [.command])
                    .disabled(model.bestPassword.isEmpty)

                Button("Analyze Input") { model.analyze() }
                    .keyboardShortcut("a", modifiers: [.command, .shift])
                    .disabled(model.analyzeInput.isEmpty)

                Divider()

                Button("Install Command-Line Tool…") {
                    InstallCLI.run()
                }
            }

            // MARK: Remove menu items that do nothing in this app
            CommandGroup(replacing: .saveItem)      { }
            CommandGroup(replacing: .printItem)     { }
            CommandGroup(replacing: .toolbar)       { }
            CommandGroup(replacing: .sidebar)       { }
            CommandGroup(replacing: .textFormatting) { }
            CommandGroup(replacing: .textEditing)   { }
            CommandGroup(replacing: .undoRedo)      { }

            // MARK: Help
            CommandGroup(replacing: .help) {
                HelpMenuContent()
            }
        }

        // Help window scene, opened from the Help menu or meowpass://help
        Window("MeowPassword Help", id: "help") {
            HelpView()
        }
        .defaultSize(width: 620, height: 700)

        // MeowGram window: compose steganographic cat-mail and decode drops.
        Window("MeowGram", id: "meowgram") {
            MeowGramView()
                .environmentObject(meowGramModel)
        }
        .defaultSize(width: 820, height: 700)
        .windowResizability(.contentMinSize)

        MenuBarExtra {
            MenuBarView().environmentObject(model)
        } label: {
            Image(systemName: "cat.fill")
        }
        .menuBarExtraStyle(.menu)
    }

    private func handleURL(_ url: URL) {
        switch url.host {
        case "generate":
            model.generate()
        case "copy":
            model.generateAndCopy()
        default:
            break
        }
    }
}

// MARK: - MeowGram menu item (needs @Environment for openWindow)

private struct MeowGramMenuItem: View {
    @Environment(\.openWindow) private var openWindow
    var body: some View {
        Button("New MeowGram…") {
            openWindow(id: "meowgram")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut("m", modifiers: [.command, .shift])
    }
}

// MARK: - Help menu content (needs @Environment for openWindow)

private struct HelpMenuContent: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button("MeowPassword Help") {
            openWindow(id: "help")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut("?", modifiers: [.command])

        Divider()

        Button("Project on GitHub") {
            openURL("https://github.com/SpaceTrucker2196/MeowPassword")
        }
        Button("Report an Issue…") {
            openURL("https://github.com/SpaceTrucker2196/MeowPassword/issues/new")
        }
        Button("Release Notes") {
            openURL("https://github.com/SpaceTrucker2196/MeowPassword/releases")
        }
    }

    private func openURL(_ string: String) {
        if let url = URL(string: string) {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - About panel

private func showAboutPanel() {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

    let credits = NSMutableAttributedString(
        string: "A cat-name-based password generator with catified complexity scoring.\n\n",
        attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
            .foregroundColor: NSColor.labelColor
        ]
    )
    credits.append(NSAttributedString(
        string: "Menu bar, Shortcuts, Services, and URL-scheme integration all wrap the same `meowpass` CLI.\n\n",
        attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
    ))
    credits.append(NSAttributedString(
        string: "Built with Swift + SwiftUI · MIT License\n© 2026 Jeffrey Kunzelman",
        attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
    ))

    let opts: [NSApplication.AboutPanelOptionKey: Any] = [
        .applicationName: "MeowPassword",
        .applicationVersion: version,
        .version: "Build \(build)",
        .credits: credits
    ]

    NSApp.activate(ignoringOtherApps: true)
    NSApp.orderFrontStandardAboutPanel(options: opts)
}

// MARK: - AppKit delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var model: GenerationModel?
    private let servicesBridge = ServicesBridge()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.servicesProvider = servicesBridge
        NSUpdateDynamicServices()
    }
}
