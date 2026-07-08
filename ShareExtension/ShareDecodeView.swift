import SwiftUI
import UIKit
import MeowUI
import MeowGramKit

/// The decode UI shown in the share sheet. Decodes on appear; if the message
/// is passphrase-locked, the user can type the passphrase and decode again.
struct ShareDecodeView: View {
    let imageData: Data?
    var close: () -> Void

    @State private var preview: UIImage?
    @State private var passphrase = ""
    @State private var message: String?
    @State private var guid: String?
    @State private var error: String?
    @State private var decoding = false

    var body: some View {
        ZStack {
            GameShow.bg.ignoresSafeArea()
            SparkleField(count: 30).ignoresSafeArea()
            VStack(spacing: 12) {
                header
                if let preview {
                    Image(uiImage: preview).resizable().aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(GameShow.inkBlack, lineWidth: 1.5))
                }

                if decoding {
                    EmbedGeneratingView(label: "DECODING…")
                        .frame(height: 170)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if let message {
                    messagePanel(message)
                } else {
                    lockedPanel
                }

                Spacer(minLength: 0)
                Button { close() } label: { Label("DONE", systemImage: "checkmark") }
                    .buttonStyle(NeonButton(fill: GameShow.neonCyan))
            }
            .padding(16)
        }
        .preferredColorScheme(.light)
        .onAppear {
            preview = imageData.flatMap { UIImage(data: $0) }
            decode()
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "cat.fill").font(.system(size: 20, weight: .black))
                .foregroundStyle(GameShow.neonYellow)
                .shadow(color: GameShow.inkBlack, radius: 0, x: 1, y: 1)
            Text("DECODE MEOWGRAM")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: GameShow.inkBlack, radius: 0, x: 2, y: 2)
            Spacer()
        }
    }

    private func messagePanel(_ msg: String) -> some View {
        GamePanel(tint: GameShow.neonYellow) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    tag("MESSAGE!", tint: GameShow.hotPink)
                    if let guid { Text("🐱 \(guid.prefix(8))")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(GameShow.inkBlack.opacity(0.5)) }
                }
                HStack {
                    Text(msg).font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundStyle(GameShow.neonYellow).textSelection(.enabled).padding(10)
                    Spacer()
                    Button { UIPasteboard.general.string = msg } label: {
                        Image(systemName: "doc.on.clipboard.fill")
                            .foregroundStyle(GameShow.inkBlack).padding(7)
                            .background(Circle().fill(GameShow.neonYellow))
                    }.padding(.trailing, 6)
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(GameShow.inkBlack))
            }
        }
    }

    private var lockedPanel: some View {
        GamePanel(tint: GameShow.neonLime) {
            VStack(alignment: .leading, spacing: 8) {
                tag(error == nil ? "LOCKED?" : "HMM…", tint: GameShow.magenta)
                if let error {
                    Text(error).font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(GameShow.inkBlack)
                }
                HStack(spacing: 8) {
                    TextField("Passphrase", text: $passphrase)
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .autocorrectionDisabled().textInputAutocapitalization(.never)
                        .padding(7)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(GameShow.inkBlack, lineWidth: 1.5))
                        .foregroundStyle(GameShow.inkBlack)
                    Button { decode() } label: { Label("DECODE", systemImage: "eye.fill") }
                        .buttonStyle(NeonButton(fill: GameShow.hotPink, text: .white))
                        .fixedSize()
                }
            }
        }
    }

    private func tag(_ text: String, tint: Color) -> some View {
        Text(text).font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 2)
            .background(Capsule().fill(tint).overlay(Capsule().stroke(GameShow.inkBlack, lineWidth: 1.5)))
    }

    private func decode() {
        guard let data = imageData else { error = "No image was shared."; return }
        decoding = true; error = nil
        let pass = passphrase.isEmpty ? nil : passphrase
        Task {
            do {
                let (m, g): (String, String?) = try await Task.detached {
                    let image = try ColorImageIO.readRGBImage(data: data)
                    let decoded = try MeowGram.readMessage(from: image, passphrase: pass)
                    return (decoded.message, decoded.guid)
                }.value
                message = m; guid = g
            } catch {
                message = nil
                self.error = (error as? CustomStringConvertible)?.description ?? error.localizedDescription
            }
            decoding = false
        }
    }
}
