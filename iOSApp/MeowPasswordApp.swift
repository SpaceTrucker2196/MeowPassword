import SwiftUI
import MeowUI

@main
struct MeowPasswordApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
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
