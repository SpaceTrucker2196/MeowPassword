import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct MeowGramView: View {
    @EnvironmentObject var model: MeowGramModel

    var body: some View {
        ZStack {
            GameShow.bg.ignoresSafeArea()
            SparkleField(count: 60).ignoresSafeArea()

            VStack(spacing: 12) {
                header
                modeToggle
                if model.mode == .compose { composePane } else { decodePane }
                if let status = model.statusText { statusBanner(status) }
                if let err = model.lastError { errorBanner(err) }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: 900)
            .frame(maxWidth: .infinity)
        }
        .frame(minWidth: 720, minHeight: 620)
        .onDrop(of: [.fileURL], isTargeted: $model.isDropTargeted) { model.handleDrop(providers: $0) }
        .task { model.loadCatalog() }
    }

    // MARK: header + toggle

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "cat.fill")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(GameShow.neonYellow)
                .shadow(color: GameShow.inkBlack, radius: 0, x: 1, y: 1)
            Text("MEOWGRAM")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: GameShow.inkBlack, radius: 0, x: 2, y: 2)
            Text("にゃんメール")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 12) {
            ForEach(MeowGramModel.Mode.allCases, id: \.self) { m in
                Button { model.mode = m } label: {
                    Label(m.rawValue, systemImage: m == .compose ? "square.and.pencil" : "eye.fill")
                }
                .buttonStyle(NeonButton(fill: model.mode == m ? GameShow.neonYellow : GameShow.paperWhite))
            }
        }
    }

    // MARK: compose

    private var composePane: some View {
        HStack(alignment: .top, spacing: 12) {
            GamePanel(tint: GameShow.neonCyan) {
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("PICK A CAT!", tint: GameShow.hotPink)
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 8)], spacing: 8) {
                            ForEach(model.catalog) { entry in
                                MeowgramThumb(entry: entry, isSelected: model.selectedID == entry.id)
                                    .onTapGesture { model.selectedID = entry.id }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .frame(minWidth: 300, maxWidth: 360)

            VStack(spacing: 12) {
                GamePanel(tint: GameShow.neonLime) {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("SECRET MESSAGE", tint: GameShow.magenta)
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8).fill(.white)
                            TextEditor(text: $model.message)
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .foregroundStyle(GameShow.inkBlack)
                                .scrollContentBackground(.hidden)
                                .padding(6)
                            if model.message.isEmpty {
                                Text("PSST… WHISPER SOMETHING")
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(GameShow.inkBlack.opacity(0.3))
                                    .padding(.horizontal, 11).padding(.vertical, 14)
                                    .allowsHitTesting(false)
                            }
                        }
                        .frame(height: 84)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(GameShow.inkBlack, lineWidth: 1.5))

                        HStack {
                            Text("\(model.payloadBytesUsed)/\(model.payloadBytesMax) BYTES")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(model.isOverBudget ? Color.red : GameShow.inkBlack.opacity(0.6))
                            Spacer()
                        }

                        passphraseField(placeholder: "PASSPHRASE (OPTIONAL)",
                                        secure: false,
                                        onGenerate: { model.generatePassphrase() })

                        Button { model.embed() } label: {
                            Label(model.isEmbedding ? "EMBEDDING…" : "EMBED!",
                                  systemImage: "wand.and.stars")
                        }
                        .buttonStyle(NeonButton(fill: GameShow.neonYellow))
                        .disabled(model.selectedID == nil || model.message.isEmpty
                                  || model.isOverBudget || model.isEmbedding)
                        .opacity((model.selectedID == nil || model.message.isEmpty
                                  || model.isOverBudget || model.isEmbedding) ? 0.6 : 1)
                    }
                }

                GamePanel(tint: GameShow.neonYellow) {
                    VStack(spacing: 8) {
                        sectionLabel("PREVIEW", tint: GameShow.neonCyan)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(GameShow.inkBlack.opacity(0.1))
                            if let img = model.previewImage {
                                Image(nsImage: img).resizable().aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                VStack(spacing: 6) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 30, weight: .bold))
                                    Text("Embed to preview")
                                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                                }
                                .foregroundStyle(GameShow.inkBlack.opacity(0.4))
                            }
                        }
                        .frame(maxHeight: 240)

                        HStack(spacing: 10) {
                            Button { model.sendViaMail() } label: {
                                Label("SEND!", systemImage: "paperplane.fill")
                            }
                            .buttonStyle(NeonButton(fill: GameShow.hotPink, text: .white))
                            Button { model.copyToPasteboard() } label: {
                                Label("COPY", systemImage: "doc.on.doc.fill")
                            }
                            .keyboardShortcut("c", modifiers: [.command])
                            .buttonStyle(NeonButton(fill: GameShow.neonLime))
                            Button { model.savePNG() } label: {
                                Label("SAVE", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(NeonButton(fill: GameShow.neonCyan))
                        }
                        .disabled(model.encodedPNG == nil)
                        .opacity(model.encodedPNG == nil ? 0.6 : 1)
                    }
                }
            }
        }
    }

    // MARK: decode

    private var decodePane: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(GameShow.paperWhite.opacity(model.isDropTargeted ? 1.0 : 0.85))
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(model.isDropTargeted ? GameShow.neonLime : GameShow.neonCyan,
                            style: StrokeStyle(lineWidth: 4, dash: [10, 8]))
                VStack(spacing: 8) {
                    if model.isDecoding {
                        ProgressView().controlSize(.large)
                    } else {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 40, weight: .black))
                        Text("DROP A MEOWGRAM PNG HERE")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                        Text("かくされたメッセージをさがす")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .opacity(0.6)
                    }
                }
                .foregroundStyle(GameShow.inkBlack.opacity(0.6))
            }
            .frame(minHeight: 200)

            HStack(spacing: 10) {
                Button { model.pasteAndDecode() } label: {
                    Label("PASTE MEOWGRAM", systemImage: "doc.on.clipboard.fill")
                }
                .keyboardShortcut("v", modifiers: [.command])
                .buttonStyle(NeonButton(fill: GameShow.neonCyan))
            }

            passphraseField(placeholder: "PASSPHRASE (IF LOCKED)")

            if let img = model.decodedImage {
                Image(nsImage: img).resizable().aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(GameShow.inkBlack, lineWidth: 1.5))
            }

            if let msg = model.decodedMessage {
                GamePanel(tint: GameShow.neonYellow) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            sectionLabel("MESSAGE!", tint: GameShow.hotPink)
                            if let guid = model.decodedGUID {
                                Text("🐱 authentic · \(guid.prefix(8))")
                                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(GameShow.inkBlack.opacity(0.5))
                            }
                        }
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 10).fill(GameShow.inkBlack)
                            HStack(alignment: .top) {
                                Text(msg)
                                    .font(.system(size: 13, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(GameShow.neonYellow)
                                    .textSelection(.enabled)
                                    .padding(.horizontal, 10).padding(.vertical, 8)
                                Spacer()
                                Button { Clipboard.copy(msg) } label: {
                                    Image(systemName: "doc.on.clipboard.fill")
                                        .font(.system(size: 13, weight: .black))
                                        .foregroundStyle(GameShow.inkBlack)
                                        .padding(6)
                                        .background(Circle().fill(GameShow.neonYellow))
                                        .overlay(Circle().stroke(GameShow.inkBlack, lineWidth: 1.5))
                                }
                                .buttonStyle(.plain)
                                .padding(6)
                                .help("Copy message")
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: shared bits

    private func passphraseField(
        placeholder: String, secure: Bool = true, onGenerate: (() -> Void)? = nil
    ) -> some View {
        let trailing: CGFloat = onGenerate != nil ? 40 : 8
        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8).fill(.white)
            Group {
                if secure {
                    SecureField("", text: $model.passphrase)
                } else {
                    // Visible so the sender can read the voice key aloud.
                    TextField("", text: $model.passphrase)
                }
            }
            .textFieldStyle(.plain)
            .font(.system(size: 12, weight: .heavy, design: .monospaced))
            .foregroundStyle(GameShow.inkBlack)
            .padding(.vertical, 8)
            .padding(.leading, 8)
            .padding(.trailing, trailing)

            if model.passphrase.isEmpty {
                Text(placeholder)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(GameShow.inkBlack.opacity(0.3))
                    .padding(.leading, 9)
                    .allowsHitTesting(false)
            }

            if let onGenerate {
                HStack {
                    Spacer()
                    Button(action: onGenerate) {
                        Image(systemName: "dice.fill")
                            .font(.system(size: 12, weight: .black))
                            .foregroundStyle(GameShow.inkBlack)
                            .padding(5)
                            .background(Circle().fill(GameShow.neonYellow))
                            .overlay(Circle().stroke(GameShow.inkBlack, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 5)
                    .help("Generate a voice-friendly cat key")
                }
            }
        }
        .frame(height: 32)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(GameShow.inkBlack, lineWidth: 1.5))
    }

    private func sectionLabel(_ text: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(Capsule().fill(tint).overlay(Capsule().stroke(GameShow.inkBlack, lineWidth: 1.5)))
            Spacer()
        }
    }

    private func statusBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(GameShow.inkBlack)
            Text(message)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(GameShow.inkBlack)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(GameShow.neonLime)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(GameShow.inkBlack, lineWidth: 2)))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(GameShow.neonYellow)
            Text(message)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.red)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(GameShow.inkBlack, lineWidth: 2)))
    }
}

// MARK: - Thumbnail cell

private struct MeowgramThumb: View {
    let entry: MeowgramCatalog.Entry
    let isSelected: Bool
    @State private var thumb: NSImage?

    var body: some View {
        ZStack {
            if let thumb {
                Image(nsImage: thumb).resizable().aspectRatio(contentMode: .fill)
            } else {
                GameShow.inkBlack.opacity(0.1)
            }
        }
        .frame(width: 84, height: 105)   // 4:5 like the sources
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? GameShow.neonYellow : GameShow.inkBlack,
                        lineWidth: isSelected ? 4 : 1.5)
        )
        .task(id: entry.id) {
            let url = entry.url
            thumb = await Task.detached { ThumbnailCache.shared.thumbnail(for: url) }.value
        }
    }
}
