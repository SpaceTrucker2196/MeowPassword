import SwiftUI
import UIKit
import MeowUI
import MeowGramKit

/// The decode UI shown in the share sheet. Decodes on appear; if the message
/// is passphrase-locked, the user can type the passphrase and decode again.
struct ShareDecodeView: View {
    let imageData: Data?
    var close: () -> Void

    @Environment(\.theme) private var theme
    @State private var preview: UIImage?
    @State private var passphrase = ""
    @State private var message: String?
    @State private var guid: String?
    @State private var error: String?
    @State private var decoding = false

    var body: some View {
        ZStack {
            ThemedBackground().ignoresSafeArea()
            SparkleField(count: 30).ignoresSafeArea()
            VStack(spacing: 12) {
                header
                if let preview {
                    // The decode rain lays over the MeowGram, so it's the same
                    // size and the image itself reads as being decoded.
                    Image(uiImage: preview).resizable().aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 150)
                        .overlay { if decoding { MatrixDecodeView(label: "DECODING…") } }
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.bind, lineWidth: 1.5))
                }

                // Bright callout so the passphrase field is unmissable.
                VStack(alignment: .leading, spacing: 6) {
                    tag("PASSPHRASE", tint: theme.command)
                    TextField("Enter it if this MeowGram is locked", text: $passphrase)
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundStyle(theme.bind)
                        .autocorrectionDisabled().textInputAutocapitalization(.never)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.bind, lineWidth: 1.5))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(theme.celebrate))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.bind, lineWidth: 2))

                // Decode (and the animation) only run once tapped, with an image.
                Button { decode() } label: { Label("DECODE MEOWGRAM!", systemImage: "envelope.open.fill") }
                    .buttonStyle(NeonButton(fill: theme.command, text: .white))
                    .disabled(imageData == nil || decoding)

                if let message {
                    messagePanel(message)
                } else if let error, !decoding {
                    GamePanel(tint: theme.positive) {
                        VStack(alignment: .leading, spacing: 6) {
                            tag("HMM…", tint: theme.commandDeep)
                            Text(error).font(.system(size: 11, weight: .heavy, design: .monospaced))
                                .foregroundStyle(theme.bind)
                        }
                    }
                }

                Spacer(minLength: 0)
                Button { close() } label: { Label("DONE", systemImage: "checkmark") }
                    .buttonStyle(NeonButton(fill: theme.cool))
            }
            .padding(16)
        }
        // Stage the image only — decoding waits for the DECODE MEOWGRAM! tap.
        .onAppear { preview = imageData.flatMap { UIImage(data: $0) } }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "cat.fill").font(.system(size: 20, weight: .black))
                .foregroundStyle(theme.celebrate)
                .shadow(color: theme.bind, radius: 0, x: 1, y: 1)
            Text("DECODE MEOWGRAM")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: theme.bind, radius: 0, x: 2, y: 2)
            Spacer()
        }
    }

    private func messagePanel(_ msg: String) -> some View {
        GamePanel(tint: theme.celebrate) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    tag("MESSAGE!", tint: theme.command)
                    if let guid { Text("🐱 \(guid.prefix(8))")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundStyle(theme.bind.opacity(0.5)) }
                }
                HStack {
                    Text(msg).font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundStyle(theme.celebrate).textSelection(.enabled).padding(10)
                    Spacer()
                    Button { UIPasteboard.general.string = msg } label: {
                        Image(systemName: "doc.on.clipboard.fill")
                            .foregroundStyle(theme.bind).padding(7)
                            .background(Circle().fill(theme.celebrate))
                    }.padding(.trailing, 6)
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.bind))
            }
        }
    }

    private func tag(_ text: String, tint: Color) -> some View {
        Text(text).font(.system(size: 13, weight: .black, design: .rounded))
            .foregroundStyle(.white).padding(.horizontal, 8).padding(.vertical, 2)
            .background(Capsule().fill(tint).overlay(Capsule().stroke(theme.bind, lineWidth: 1.5)))
    }

    private func decode() {
        guard let data = imageData else { error = "No image was shared."; return }
        decoding = true; error = nil
        let pass = passphrase.isEmpty ? nil : passphrase
        Task {
            // Hold the animation long enough to land (decode is near-instant).
            async let minShow: Void = Task.sleep(nanoseconds: 1_100_000_000)
            do {
                let (m, g): (String, String?) = try await Task.detached {
                    let image = try ColorImageIO.readRGBImage(data: data)
                    let decoded = try MeowGram.readMessage(from: image, passphrase: pass)
                    return (decoded.message, decoded.guid)
                }.value
                try? await minShow
                message = m; guid = g
            } catch {
                try? await minShow
                message = nil
                self.error = (error as? CustomStringConvertible)?.description ?? error.localizedDescription
            }
            decoding = false
        }
    }
}
