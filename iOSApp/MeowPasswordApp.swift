import SwiftUI
import MeowUI

@main
struct MeowPasswordApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                // The game-show palette is a fixed print aesthetic — it must
                // render identically regardless of the device's light/dark
                // setting, so text never lands white-on-white.
                .preferredColorScheme(.light)
        }
    }
}

struct RootView: View {
    // `-openMeowGram` launch arg opens MeowGram immediately (QA / screenshots).
    @State private var showMeowGram = ProcessInfo.processInfo.arguments.contains("-openMeowGram")
    var body: some View {
        GenerateView(onMeowGram: { showMeowGram = true })
            .fullScreenCover(isPresented: $showMeowGram) {
                MeowGramScreen(onClose: { showMeowGram = false })
            }
    }
}
