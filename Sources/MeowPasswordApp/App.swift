import SwiftUI
import AppKit
import MeowUI
import MeowThemeStore

@main
struct MeowPasswordApp: App {
    @StateObject private var model = GenerationModel()
    @StateObject private var meowGramModel = MeowGramModel()
    @StateObject private var themeManager: ThemeManager
    @StateObject private var themeStore: ThemeStore
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        let manager = ThemeManager()
        _themeManager = StateObject(wrappedValue: manager)
        _themeStore = StateObject(wrappedValue: ThemeStore(themeManager: manager))
    }

    var body: some Scene {
        WindowGroup("MeowPassword", id: "main") {
            ContentView()
                .environmentObject(model)
                .environmentObject(themeManager)
                .environmentObject(themeStore)
                .environment(\.theme, themeManager.current)
                // The theme, not the OS setting, decides the scheme — every
                // theme is a fixed print aesthetic.
                .preferredColorScheme(themeManager.current.colorScheme)
                .task {
                    // Rebuild pack ownership from the local entitlement cache,
                    // then load prices. On non-App-Store builds (DMG) product
                    // loading fails and packs simply stay locked.
                    await themeStore.refreshEntitlements()
                    await themeStore.loadProducts()
                }
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

                MeowGramMenuItem(model: meowGramModel)

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

                Divider()

                // Discoverability alias for Settings — the Theme Studio is
                // the only settings surface.
                ThemeStudioMenuItem()
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
                .environmentObject(themeManager)
                .environment(\.theme, themeManager.current)
                .preferredColorScheme(themeManager.current.colorScheme)
        }
        .defaultSize(width: 620, height: 700)

        // MeowGram window: compose steganographic cat-mail and decode drops.
        Window("MeowGram", id: "meowgram") {
            MeowGramView()
                .environmentObject(meowGramModel)
                .environmentObject(themeManager)
                .environment(\.theme, themeManager.current)
                .preferredColorScheme(themeManager.current.colorScheme)
        }
        .defaultSize(width: 820, height: 700)
        .windowResizability(.contentMinSize)

        // Theme Studio lives in Settings (Cmd+,): pick a look, buy a pack,
        // restore purchases.
        Settings {
            ThemeStudioView()
                .environmentObject(themeManager)
                .environmentObject(themeStore)
                .environment(\.theme, themeManager.current)
                .preferredColorScheme(themeManager.current.colorScheme)
                .frame(minWidth: 480, minHeight: 560)
        }

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

// MARK: - Theme Studio menu item (opens the Settings scene)

private struct ThemeStudioMenuItem: View {
    var body: some View {
        Group {
            if #available(macOS 14.0, *) {
                SettingsLink { Text("Theme Studio…") }
            } else {
                Button("Theme Studio…") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
        }
        .keyboardShortcut("t", modifiers: [.command, .shift])
    }
}

// MARK: - MeowGram menu item (needs @Environment for openWindow)

private struct MeowGramMenuItem: View {
    @Environment(\.openWindow) private var openWindow
    let model: MeowGramModel
    var body: some View {
        Button("New MeowGram…") {
            model.mode = .compose
            openWindow(id: "meowgram")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut("m", modifiers: [.command, .shift])

        Button("Decode MeowGram…") {
            model.mode = .decode
            openWindow(id: "meowgram")
            NSApp.activate(ignoringOtherApps: true)
        }
        .keyboardShortcut("d", modifiers: [.command, .shift])
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
        string: String(localized: "A cat-name-based password generator with catified complexity scoring.\n\n"),
        attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
            .foregroundColor: NSColor.labelColor
        ]
    )
    credits.append(NSAttributedString(
        string: String(localized: "Menu bar, Shortcuts, Services, and URL-scheme integration all wrap the same `meowpass` CLI.\n\n"),
        attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
    ))
    credits.append(NSAttributedString(
        string: String(localized: "Built with Swift + SwiftUI · MIT License\n© 2026 Jeffrey Kunzelman"),
        attributes: [
            .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
            .foregroundColor: NSColor.tertiaryLabelColor
        ]
    ))

    let opts: [NSApplication.AboutPanelOptionKey: Any] = [
        .applicationName: "MeowPassword",
        .applicationVersion: version,
        .version: String(format: String(localized: "Build %@"), build),
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
