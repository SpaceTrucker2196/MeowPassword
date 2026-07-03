import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var model: GenerationModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !model.bestPassword.isEmpty {
                Text(model.bestPassword)
                    .font(.system(.caption, design: .monospaced))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            Button("★ GENERATE + COPY!") {
                model.generateAndCopy()
            }
            .keyboardShortcut("g", modifiers: [.command])

            Button("Generate (せいせい)") {
                model.generate()
                openWindow(id: "main")
            }

            if !model.bestPassword.isEmpty {
                Button("Copy Best (コピー)") {
                    model.copyBest()
                }
                .keyboardShortcut("c", modifiers: [.command])
            }

            Divider()

            Button("Open MeowPassword… (ひらく)") {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            }

            Divider()

            Button("Quit") { NSApp.terminate(nil) }
                .keyboardShortcut("q", modifiers: [.command])
        }
        .padding(6)
    }
}
