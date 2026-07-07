import SwiftUI
import UIKit
import ImageIO
import MeowUI
import MeowGramKit
import MeowPassCore

/// The compose UI shown inside Messages: pick a cat, type a secret message
/// (optionally locked with a passphrase), and drop the MeowGram into the chat.
struct MeowGramComposeView: View {
    var isCompact: () -> Bool
    var expand: () -> Void
    var insert: (URL) -> Void

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
            GameShow.bg.ignoresSafeArea()
            SparkleField(count: 30).ignoresSafeArea()
            if isCompact() {
                Button(action: expand) {
                    Label("TAP TO MAKE A MEOWGRAM", systemImage: "cat.fill")
                }
                .buttonStyle(NeonButton(fill: GameShow.neonYellow))
                .padding()
            } else {
                composer
            }
        }
        .task { if catalog.isEmpty { catalog = MeowGramCatalog.load() } }
    }

    private var composer: some View {
        VStack(spacing: 10) {
            GamePanel(tint: GameShow.neonLime) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        label("SECRET MESSAGE", tint: GameShow.magenta)
                        Text("\(message.utf8.count)/\(MeowGram.maxMessageBytes)")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(message.utf8.count > MeowGram.maxMessageBytes ? .red : GameShow.inkBlack.opacity(0.6))
                    }
                    TextField("Psst… whisper something", text: $message, axis: .vertical)
                        .lineLimit(1...2)
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .padding(7)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(GameShow.inkBlack, lineWidth: 1.5))
                    HStack(spacing: 8) {
                        TextField("Passphrase (optional)", text: $passphrase)
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .autocorrectionDisabled().textInputAutocapitalization(.never)
                            .padding(7)
                            .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(GameShow.inkBlack, lineWidth: 1.5))
                        Button { passphrase = MeowPass.meowKey() } label: {
                            Text("GENERATE")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(GameShow.inkBlack)
                                .padding(.horizontal, 10).padding(.vertical, 9)
                                .background(Capsule().fill(GameShow.neonYellow))
                                .overlay(Capsule().stroke(GameShow.inkBlack, lineWidth: 1.5))
                        }
                    }
                }
            }

            GamePanel(tint: GameShow.neonCyan) {
                VStack(alignment: .leading, spacing: 6) {
                    label("PICK A CAT!", tint: GameShow.hotPink)
                    GeometryReader { geo in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
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
            .buttonStyle(NeonButton(fill: GameShow.hotPink, text: .white))
            .disabled(!canSend)

            if let error {
                Text(error).font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(.white).padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.red))
            }
        }
        .padding(12)
    }

    private func send() {
        guard let entry = catalog.first(where: { $0.id == selectedID }), !message.isEmpty else { return }
        busy = true; error = nil
        let path = entry.url.path, id = entry.id, msg = message
        let pass = passphrase.isEmpty ? nil : passphrase
        Task {
            do {
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
                .foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 2)
                .background(Capsule().fill(tint).overlay(Capsule().stroke(GameShow.inkBlack, lineWidth: 1.5)))
            Spacer()
        }
    }
}

private struct Thumb: View {
    let entry: MeowGramCatalog.Entry
    let selected: Bool
    var height: CGFloat = 100
    @State private var img: UIImage?
    var body: some View {
        let h = max(80, height)
        ZStack {
            if let img { Image(uiImage: img).resizable().aspectRatio(contentMode: .fill) }
            else { GameShow.inkBlack.opacity(0.1) }
        }
        .frame(width: h * 0.8, height: h)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10)
            .stroke(selected ? GameShow.neonYellow : GameShow.inkBlack, lineWidth: selected ? 4 : 1.5))
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
