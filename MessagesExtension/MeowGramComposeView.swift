import SwiftUI
import UIKit
import ImageIO
import MeowUI
import MeowGramKit
import MeowGramAssets
import MeowPassCore

/// The compose UI shown inside Messages: pick a cat, type a secret message
/// (optionally locked with a passphrase), and drop the MeowGram into the chat.
struct MeowGramComposeView: View {
    @ObservedObject var state: ExtensionState
    var expand: () -> Void
    var insert: (URL) -> Void

    @Environment(\.theme) private var theme
    @State private var catalog: [MeowGramCatalog.Entry] = []
    @State private var selectedID: String?
    @State private var message = ""
    @State private var passphrase = ""
    @State private var busy = false
    @State private var error: String?

    private var canSend: Bool { selectedID != nil && !message.isEmpty
        && message.utf8.count <= MeowGram.maxMessageBytes && !busy }

    var body: some View {
        ZStack {
            ThemedBackground().ignoresSafeArea()
            SparkleField(count: 30).ignoresSafeArea()
            if state.isExpanded {
                composer
            } else {
                Button(action: expand) {
                    Label("TAP TO MAKE A MEOWGRAM", systemImage: "cat.fill")
                }
                .buttonStyle(NeonButton(fill: theme.celebrate))
                .padding()
            }
        }
        // Only enumerate the cats once the extension is expanded — keeps the
        // compact "tap to open" bar instant to load.
        .task(id: state.isExpanded) {
            if state.isExpanded && catalog.isEmpty { catalog = MeowGramCatalog.load(set: theme.meowgramSet) }
        }
    }

    private var composer: some View {
        VStack(spacing: 10) {
            GamePanel(tint: theme.positive) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        label("SECRET MESSAGE", tint: theme.commandDeep)
                        Text("\(message.utf8.count)/\(MeowGram.maxMessageBytes)")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(message.utf8.count > MeowGram.maxMessageBytes ? theme.danger : theme.bind.opacity(0.6))
                    }
                    TextField("Psst… whisper something", text: $message, axis: .vertical)
                        .lineLimit(1...2)
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .padding(7)
                        .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.bind, lineWidth: 1.5))
                    HStack(spacing: 8) {
                        TextField("Passphrase (optional)", text: $passphrase)
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .autocorrectionDisabled().textInputAutocapitalization(.never)
                            .padding(7)
                            .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.bind, lineWidth: 1.5))
                        Button { passphrase = MeowPass.meowKey() } label: {
                            Text("GENERATE")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(theme.bind)
                                .padding(.horizontal, 10).padding(.vertical, 9)
                                .background(Capsule().fill(theme.celebrate))
                                .overlay(Capsule().stroke(theme.bind, lineWidth: 1.5))
                        }
                    }
                }
            }

            GamePanel(tint: theme.cool) {
                VStack(alignment: .leading, spacing: 6) {
                    label("PICK A CAT!", tint: theme.command)
                    GeometryReader { geo in
                        ScrollView(.horizontal, showsIndicators: false) {
                            // Lazy so only visible cats decode a thumbnail — the
                            // extension has a tight memory/launch budget.
                            LazyHStack(spacing: 8) {
                                ForEach(catalog) { entry in
                                    Thumb(entry: entry, selected: selectedID == entry.id, height: geo.size.height)
                                        .onTapGesture { selectedID = entry.id }
                                }
                            }
                        }
                    }
                    .frame(minHeight: 90)
                }
            }
            .frame(maxHeight: .infinity)

            Button(action: send) {
                Label(busy ? "SENDING…" : "SEND MEOWGRAM", systemImage: "paperplane.fill")
            }
            .buttonStyle(NeonButton(fill: theme.command, text: theme.textOnCommand))
            .disabled(!canSend)

            if let error {
                Text(error).font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(.white).padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(theme.danger))
            }
        }
        .padding(12)
        .overlay {
            if busy {
                EmbedGeneratingView(label: "SENDING…")
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(8)
            }
        }
    }

    private func send() {
        guard let entry = catalog.first(where: { $0.id == selectedID }), !message.isEmpty else { return }
        busy = true; error = nil
        let path = entry.url.path, id = entry.id, msg = message
        let pass = passphrase.isEmpty ? nil : passphrase
        Task {
            do {
                async let minShow: Void = Task.sleep(nanoseconds: 1_100_000_000)  // let the animation land
                let url: URL = try await Task.detached {
                    let image = try ColorImageIO.readRGBImage(path: path)
                    let stego = try MeowGram.embedMessage(msg, passphrase: pass, into: image)
                    let data = try ColorImageIO.pngData(stego)
                    let dir = FileManager.default.temporaryDirectory
                        .appendingPathComponent("MeowGrams", isDirectory: true)
                    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                    let out = dir.appendingPathComponent("MeowGram-\(id)-\(UUID().uuidString).png")
                    try data.write(to: out)
                    return out
                }.value
                try? await minShow
                insert(url)
                busy = false
            } catch {
                self.error = (error as? CustomStringConvertible)?.description ?? error.localizedDescription
                busy = false
            }
        }
    }

    private func label(_ text: String, tint: Color) -> some View {
        HStack {
            Text(text).font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(theme.textOnCommand).padding(.horizontal, 8).padding(.vertical, 2)
                .background(Capsule().fill(tint).overlay(Capsule().stroke(theme.bind, lineWidth: 1.5)))
            Spacer()
        }
    }
}

private struct Thumb: View {
    let entry: MeowGramCatalog.Entry
    let selected: Bool
    var height: CGFloat = 100
    @Environment(\.theme) private var theme
    @State private var img: UIImage?
    var body: some View {
        let h = max(80, height)
        ZStack {
            if let img { Image(uiImage: img).resizable().aspectRatio(contentMode: .fill) }
            else { theme.bind.opacity(0.1) }
        }
        .frame(width: h * 0.8, height: h)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(selected ? theme.celebrate : theme.bind, lineWidth: selected ? 4 : 1.5))
        .task(id: entry.id) {
            let url = entry.url
            img = await Task.detached {
                guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, [
                          kCGImageSourceCreateThumbnailFromImageAlways: true,
                          kCGImageSourceThumbnailMaxPixelSize: 220,
                          kCGImageSourceCreateThumbnailWithTransform: true
                      ] as CFDictionary) else { return nil }
                return UIImage(cgImage: cg)
            }.value
        }
    }
}
