import SwiftUI
import MeowUI
import MeowGramKit

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
    @State private var decodeOnOpen: Data?
    var body: some View {
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
