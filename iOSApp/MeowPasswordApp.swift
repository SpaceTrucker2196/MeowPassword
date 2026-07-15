import SwiftUI
import MeowUI
import MeowThemeStore
import MeowGramKit

@main
struct MeowPasswordApp: App {
    @StateObject private var themeManager: ThemeManager
    @StateObject private var themeStore: ThemeStore
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let manager = ThemeManager()
        _themeManager = StateObject(wrappedValue: manager)
        _themeStore = StateObject(wrappedValue: ThemeStore(themeManager: manager))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(themeManager)
                .environmentObject(themeStore)
                .environment(\.theme, themeManager.current)
                // Every theme is a fixed print aesthetic — the theme, not the
                // device's light/dark setting, decides the scheme, so text
                // never lands white-on-white.
                .preferredColorScheme(themeManager.current.colorScheme)
                .task {
                    // Rebuild pack ownership from the local entitlement cache
                    // (covers refunds and reinstalls), then load prices.
                    await themeStore.refreshEntitlements()
                    await themeStore.loadProducts()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            // Pick up purchases/selection made elsewhere (e.g. a future
            // widget or a reinstalled device) whenever we come forward.
            if phase == .active { themeManager.reload() }
        }
    }
}

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.theme) private var theme
    // `-openMeowGram` launch arg opens MeowGram immediately (QA / screenshots).
    @State private var showMeowGram = ProcessInfo.processInfo.arguments.contains("-openMeowGram")
    @State private var decodeOnOpen: Data?

    var body: some View {
        if hSize == .regular {
            // iPad (and large split view): the password system and the MeowGram
            // system live side by side, each in its own column.
            HStack(spacing: 0) {
                GenerateView(showsMeowGramButton: false, autoTour: false)
                    .frame(maxWidth: .infinity)
                Rectangle().fill(theme.bind)
                    .frame(width: 2).ignoresSafeArea()
                MeowGramScreen(embedded: true)
                    .frame(maxWidth: .infinity)
            }
        } else {
            // iPhone (and narrow split view): password system with MeowGram
            // presented full-screen from the MEOWGRAM! button.
            GenerateView(onMeowGram: { decodeOnOpen = nil; showMeowGram = true })
                .fullScreenCover(isPresented: $showMeowGram) {
                    MeowGramScreen(onClose: { showMeowGram = false }, decodeOnOpen: decodeOnOpen)
                }
                // "Decode MeowGram" share extension drops the image in the shared
                // inbox and opens meowpass://decode — load it into the decode screen.
                .onOpenURL { url in
                    guard url.host == "decode", let data = MeowGramInbox.read() else { return }
                    MeowGramInbox.clear()
                    decodeOnOpen = data
                    showMeowGram = true
                }
        }
    }
}
