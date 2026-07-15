import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MeowUI

struct MeowGramView: View {
    @EnvironmentObject var model: MeowGramModel
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack {
            ThemedBackground().ignoresSafeArea()
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
        // Theme switched while open: swap to that theme's cat set.
        .onChange(of: theme.meowgramSet) { set in model.loadCatalog(set: set) }
        .task {
            model.loadCatalog(set: theme.meowgramSet)
            #if DEBUG
            // QA: `-previewDecode` freezes the decode animation over a sample cat.
            if ProcessInfo.processInfo.arguments.contains("-previewDecode"),
               let first = model.catalog.first {
                model.mode = .decode
                model.load(fileURL: first.url)
                model.isDecoding = true
            }
            #endif
        }
    }

    // MARK: header + toggle

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "cat.fill")
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(theme.celebrate)
                .shadow(color: theme.bind, radius: 0, x: 1, y: 1)
            Text("MEOWGRAM")
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(theme.textOnFloor)
                .shadow(color: theme.bind, radius: 0, x: 2, y: 2)
            Text("にゃんメール")
                .font(.system(size: 12, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.textOnFloor.opacity(0.7))
            Spacer()
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 12) {
            ForEach(MeowGramModel.Mode.allCases, id: \.self) { m in
                Button { model.mode = m } label: {
                    Label(LocalizedStringKey(m.rawValue), systemImage: m == .compose ? "square.and.pencil" : "eye.fill")
                }
                .buttonStyle(NeonButton(fill: model.mode == m ? theme.celebrate : theme.surface))
            }
        }
    }

    // MARK: compose

    private var composePane: some View {
        HStack(alignment: .top, spacing: 12) {
            GamePanel(tint: theme.cool) {
                VStack(alignment: .leading, spacing: 6) {
                    sectionLabel("PICK A CAT!", tint: theme.command)
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
                GamePanel(tint: theme.positive) {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("SECRET MESSAGE", tint: theme.commandDeep)
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8).fill(theme.surface)
                            TextEditor(text: $model.message)
                                .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                .foregroundStyle(theme.bind)
                                .scrollContentBackground(.hidden)
                                .padding(6)
                            if model.message.isEmpty {
                                Text("PSST… WHISPER SOMETHING")
                                    .font(.system(size: 12, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(theme.bind.opacity(0.3))
                                    .padding(.horizontal, 11).padding(.vertical, 14)
                                    .allowsHitTesting(false)
                            }
                        }
                        .frame(height: 84)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.bind, lineWidth: 1.5))

                        HStack {
                            Text("\(model.payloadBytesUsed)/\(model.payloadBytesMax) BYTES")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(model.isOverBudget ? theme.danger : theme.bind.opacity(0.6))
                            Spacer()
                        }

                        passphraseField(placeholder: "PASSPHRASE (OPTIONAL)",
                                        secure: false,
                                        onGenerate: { model.generatePassphrase() })

                        Button { model.embed() } label: {
                            Label(model.isEmbedding ? LocalizedStringKey("EMBEDDING…") : LocalizedStringKey("EMBED!"),
                                  systemImage: "wand.and.stars")
                        }
                        .buttonStyle(NeonButton(fill: theme.celebrate))
                        .disabled(model.selectedID == nil || model.message.isEmpty
                                  || model.isOverBudget || model.isEmbedding)
                        .opacity((model.selectedID == nil || model.message.isEmpty
                                  || model.isOverBudget || model.isEmbedding) ? 0.6 : 1)
                    }
                }

                GamePanel(tint: theme.celebrate) {
                    VStack(spacing: 8) {
                        sectionLabel("PREVIEW", tint: theme.cool)
                        ZStack {
                            RoundedRectangle(cornerRadius: 10).fill(theme.bind.opacity(0.1))
                            if model.isEmbedding {
                                EmbedGeneratingView()
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else if let img = model.previewImage {
                                Image(nsImage: img).resizable().aspectRatio(contentMode: .fit)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            } else {
                                VStack(spacing: 6) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 30, weight: .bold))
                                    Text("Embed to preview")
                                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                                }
                                .foregroundStyle(theme.bind.opacity(0.4))
                            }
                        }
                        .frame(minHeight: 200, maxHeight: 240)

                        VStack(spacing: 8) {
                            HStack(spacing: 10) {
                                Button { model.sendViaMessages() } label: {
                                    Label("MESSAGE", systemImage: "message.fill")
                                }
                                .buttonStyle(NeonButton(fill: theme.positive))
                                Button { model.sendViaMail() } label: {
                                    Label("EMAIL", systemImage: "envelope.fill")
                                }
                                .buttonStyle(NeonButton(fill: theme.command, text: theme.textOnCommand))
                            }
                            HStack(spacing: 10) {
                                Button { model.copyToPasteboard() } label: {
                                    Label("COPY", systemImage: "doc.on.doc.fill")
                                }
                                .keyboardShortcut("c", modifiers: [.command])
                                .buttonStyle(NeonButton(fill: theme.cool))
                                Button { model.savePNG() } label: {
                                    Label("SAVE", systemImage: "square.and.arrow.down")
                                }
                                .buttonStyle(NeonButton(fill: theme.celebrate))
                            }
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
            // Decoded message lands at the top, under the mode toggle.
            if let msg = model.decodedMessage { decodedMessagePanel(msg) }

            GamePanel(tint: theme.cool) {
                VStack(spacing: 10) {
                    sectionLabel("DECODE A MEOWGRAM", tint: theme.command)

                    // The MeowGram — full width; the decode rain lays over it.
                    ZStack {
                        if let img = model.decodedImage {
                            Image(nsImage: img).resizable().aspectRatio(contentMode: .fit)
                                .frame(maxWidth: .infinity)
                                .overlay { if model.isDecoding { MatrixDecodeView(label: "DECODING…") } }
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        } else if model.isDecoding {
                            MatrixDecodeView(label: "DECODING…")
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        } else {
                            dropZone
                        }
                    }
                    .frame(minHeight: 220)

                    // Bright callout so the passphrase field is unmissable.
                    VStack(alignment: .leading, spacing: 6) {
                        sectionLabel("PASSPHRASE", tint: theme.command)
                        passphraseField(placeholder: "ENTER IT IF THIS MEOWGRAM IS LOCKED", secure: false)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(theme.celebrate))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.bind, lineWidth: 2))

                    // Primary action, full width, right under the passphrase.
                    Button { model.decodeLoaded() } label: {
                        Label("DECODE MEOWGRAM!", systemImage: "envelope.open.fill")
                    }
                    .buttonStyle(NeonButton(fill: theme.command, text: theme.textOnCommand))
                    .disabled(model.loadedData == nil || model.isDecoding)

                    // Pick the source last (or drag a PNG onto the panel above).
                    HStack(spacing: 10) {
                        Button { model.openAndLoad() } label: { Label("OPEN", systemImage: "folder") }
                            .buttonStyle(NeonButton(fill: theme.celebrate))
                        Button { model.pasteAndLoad() } label: { Label("PASTE", systemImage: "doc.on.clipboard") }
                            .keyboardShortcut("v", modifiers: [.command])
                            .buttonStyle(NeonButton(fill: theme.cool))
                    }
                }
            }
        }
    }

    private var dropZone: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.surface.opacity(model.isDropTargeted ? 1.0 : 0.85))
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(model.isDropTargeted ? theme.positive : theme.cool,
                        style: StrokeStyle(lineWidth: 4, dash: [10, 8]))
            VStack(spacing: 8) {
                Image(systemName: "arrow.down.doc.fill").font(.system(size: 40, weight: .black))
                Text("DROP A MEOWGRAM PNG HERE")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                Text("かくされたメッセージをさがす")
                    .font(.system(size: 10, weight: .heavy, design: .rounded)).opacity(0.6)
            }
            .foregroundStyle(theme.bind.opacity(0.6))
        }
    }

    private func decodedMessagePanel(_ msg: String) -> some View {
        GamePanel(tint: theme.celebrate) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    sectionLabel("MESSAGE!", tint: theme.command)
                    if let guid = model.decodedGUID {
                        Text("🐱 authentic · \(guid.prefix(8))")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundStyle(theme.bind.opacity(0.5))
                    }
                }
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10).fill(theme.bind)
                    HStack(alignment: .top) {
                        Text(msg)
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundStyle(theme.celebrate)
                            .textSelection(.enabled)
                            .padding(.horizontal, 10).padding(.vertical, 8)
                        Spacer()
                        Button { Clipboard.copy(msg) } label: {
                            Image(systemName: "doc.on.clipboard.fill")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(theme.bind)
                                .padding(6)
                                .background(Circle().fill(theme.celebrate))
                                .overlay(Circle().stroke(theme.bind, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .padding(6)
                        .help("Copy message")
                    }
                }
            }
        }
    }

    // MARK: shared bits

    private func passphraseField(
        placeholder: LocalizedStringKey, secure: Bool = true, onGenerate: (() -> Void)? = nil
    ) -> some View {
        let trailing: CGFloat = onGenerate != nil ? 96 : 8
        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8).fill(theme.surface)
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
            .foregroundStyle(theme.bind)
            .padding(.vertical, 8)
            .padding(.leading, 8)
            .padding(.trailing, trailing)

            if model.passphrase.isEmpty {
                Text(placeholder)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(theme.bind.opacity(0.3))
                    .padding(.leading, 9)
                    .allowsHitTesting(false)
            }

            if let onGenerate {
                HStack {
                    Spacer()
                    Button(action: onGenerate) {
                        Text("GENERATE")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(theme.bind)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(theme.celebrate))
                            .overlay(Capsule().stroke(theme.bind, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 5)
                    .help("Generate a voice-friendly cat key")
                }
            }
        }
        .frame(height: 32)
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.bind, lineWidth: 1.5))
    }

    private func sectionLabel(_ text: LocalizedStringKey, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(theme.textOnCommand)
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(Capsule().fill(tint).overlay(Capsule().stroke(theme.bind, lineWidth: 1.5)))
            Spacer()
        }
    }

    private func statusBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(theme.bind)
            Text(message)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(theme.bind)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.positive)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.bind, lineWidth: 2)))
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(theme.celebrate)
            Text(message)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(theme.danger)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.bind, lineWidth: 2)))
    }
}

// MARK: - Thumbnail cell

private struct MeowgramThumb: View {
    let entry: MeowgramCatalog.Entry
    let isSelected: Bool
    @Environment(\.theme) private var theme
    @State private var thumb: NSImage?

    var body: some View {
        ZStack {
            if let thumb {
                Image(nsImage: thumb).resizable().aspectRatio(contentMode: .fill)
            } else {
                theme.bind.opacity(0.1)
            }
        }
        .frame(width: 84, height: 105)   // 4:5 like the sources
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? theme.celebrate : theme.bind,
                        lineWidth: isSelected ? 4 : 1.5)
        )
        .task(id: entry.id) {
            let url = entry.url
            thumb = await Task.detached { ThumbnailCache.shared.thumbnail(for: url) }.value
        }
    }
}
