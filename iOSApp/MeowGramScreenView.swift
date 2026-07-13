import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers
import MeowUI
import MeowGramKit
import MeowGramAssets

struct MeowGramScreen: View {
    @StateObject private var model = MeowGramModeliOS()
    @State private var pickerItem: PhotosPickerItem?
    @State private var showFileImporter = false
    var onClose: () -> Void = {}
    var decodeOnOpen: Data? = nil
    /// True when shown as a column alongside the password system on iPad —
    /// hides the back button and skips the first-launch tours.
    var embedded = false

    @AppStorage("meow.tut.mg.compose.v1") private var seenCompose = false
    @AppStorage("meow.tut.mg.decode.v1") private var seenDecode = false
    @State private var showComposeTour = false
    @State private var showDecodeTour = false

    private var composeSteps: [CoachStep] {
        [
            CoachStep(title: "MEOWGRAM",
                      text: "MeowGram hides a secret message inside an ordinary-looking cat photo. Here's how to send one."),
            CoachStep(anchor: "mg.mode", title: "COMPOSE / DECODE",
                      text: "COMPOSE hides a message; DECODE reveals one you were sent. Tap to switch anytime."),
            CoachStep(anchor: "mg.message", title: "SECRET MESSAGE",
                      text: "Type the message you want to smuggle. The counter shows how much still fits."),
            CoachStep(anchor: "mg.pass", title: "PASSPHRASE",
                      text: "Optionally lock it. GENERATE mints a cat-name key that's easy to read aloud to your recipient."),
            CoachStep(anchor: "mg.cats", title: "PICK A CAT!",
                      text: "Choose the cat that carries your message — swipe sideways to browse all 100."),
            CoachStep(anchor: "mg.embed", title: "EMBED!",
                      text: "Writes the hidden message into the cat, then SHARE or SAVE the innocent-looking photo."),
        ]
    }

    private var decodeSteps: [CoachStep] {
        [
            CoachStep(title: "DECODE A MEOWGRAM",
                      text: "Got a cat photo from someone? Reveal the message hidden inside it."),
            CoachStep(anchor: "mg.dsource", title: "LOAD IT",
                      text: "Bring the cat photo in from PHOTOS, FILES, or PASTE. It just loads — nothing decodes yet."),
            CoachStep(anchor: "mg.dpass", title: "PASSPHRASE",
                      text: "If the sender locked it, type the passphrase they read you first."),
            CoachStep(anchor: "mg.ddecode", title: "DECODE MEOWGRAM!",
                      text: "Tap to reveal the hidden message — it appears in a panel up top."),
        ]
    }

    var body: some View {
        ZStack {
            GameShow.bg.ignoresSafeArea()
            SparkleField(count: 50).ignoresSafeArea()
            VStack(spacing: 10) {
                topBar
                // Compose fills the screen without scrolling (the cat picker
                // scrolls sideways instead); decode may scroll for the result.
                ScrollView {
                    if model.mode == .compose { composePane } else { decodePane }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let s = model.status { banner(s, color: GameShow.neonLime, text: GameShow.inkBlack) }
                if let e = model.errorText { banner(e, color: .red, text: .white) }
            }
            .padding(12)
        }
        .preferredColorScheme(.light)
        .task {
            model.load()
            // Opened from the "Decode MeowGram" share extension: jump to decode
            // and stage the handed-off image (the user taps DECODE MEOWGRAM!).
            if let data = decodeOnOpen {
                model.load(data: data, display: UIImage(data: data))
            }
            #if DEBUG
            // QA: `-previewDecode` freezes the decode animation over a sample cat.
            if ProcessInfo.processInfo.arguments.contains("-previewDecode"),
               let first = model.catalog.first, let data = try? Data(contentsOf: first.url) {
                seenCompose = true; seenDecode = true
                model.load(data: data, display: UIImage(data: data))
                model.isDecoding = true
            }
            if ProcessInfo.processInfo.arguments.contains("-previewEmbed"),
               let first = model.catalog.first {
                seenCompose = true; seenDecode = true
                model.selectedID = first.id
                model.message = "Send Mor Cat foods!"
                model.previewImage = UIImage(contentsOfFile: first.url.path)
            }
            #endif
            // First-launch tour for whichever mode we land on (not on iPad,
            // where both systems are already visible side by side).
            if !embedded {
                if model.mode == .compose, !seenCompose { showComposeTour = true }
                else if model.mode == .decode, !seenDecode { showDecodeTour = true }
            }
        }
        .coachTour(composeSteps, isActive: $showComposeTour)
        .coachTour(decodeSteps, isActive: $showDecodeTour)
        .onChange(of: showComposeTour) { _, active in if !active { seenCompose = true } }
        .onChange(of: showDecodeTour) { _, active in if !active { seenDecode = true } }
        .onChange(of: model.mode) { _, m in
            guard !embedded else { return }
            // First time each mode is viewed, run its tour (one at a time).
            if m == .decode, !seenDecode, !showComposeTour { showDecodeTour = true }
            if m == .compose, !seenCompose, !showDecodeTour { showComposeTour = true }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    model.load(data: data, display: UIImage(data: data))
                }
            }
        }
        .fileImporter(isPresented: $showFileImporter,
                      allowedContentTypes: [.png, .image], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                let ok = url.startAccessingSecurityScopedResource()
                defer { if ok { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url) {
                    model.load(data: data, display: UIImage(data: data))
                }
            }
        }
    }

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                if !embedded {
                    Button { onClose() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(GameShow.inkBlack)
                            .padding(8)
                            .background(Circle().fill(GameShow.paperWhite))
                            .overlay(Circle().stroke(GameShow.inkBlack, lineWidth: 2))
                    }
                }
                Text("MEOWGRAM")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: GameShow.inkBlack, radius: 0, x: 2, y: 2)
                Spacer()
                Button { if model.mode == .compose { showComposeTour = true } else { showDecodeTour = true } } label: {
                    Image(systemName: "questionmark")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(GameShow.inkBlack)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(GameShow.paperWhite))
                        .overlay(Circle().stroke(GameShow.inkBlack, lineWidth: 2))
                }
            }
            HStack(spacing: 12) {
                ForEach(MeowGramModeliOS.Mode.allCases, id: \.self) { m in
                    Button { model.mode = m } label: {
                        Label(m.rawValue, systemImage: m == .compose ? "square.and.pencil" : "eye.fill")
                    }
                    .buttonStyle(NeonButton(fill: model.mode == m ? GameShow.neonYellow : GameShow.paperWhite))
                }
            }
            .coachAnchor("mg.mode")
        }
    }

    // MARK: Compose

    private var composePane: some View {
        VStack(spacing: 10) {
            // The MeowGram result rides at the top (under the mode buttons),
            // full width: the embedding animation while working, then the
            // finished cat with SHARE / SAVE.
            if model.isEmbedding {
                GamePanel(tint: GameShow.neonYellow) {
                    EmbedGeneratingView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            } else if let img = model.previewImage {
                GamePanel(tint: GameShow.neonYellow) {
                    VStack(spacing: 8) {
                        Image(uiImage: img).resizable().aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        HStack(spacing: 8) {
                            if let url = model.encodedPNG != nil ? model.shareFileURL() : nil {
                                ShareLink(item: url) { Label("SHARE", systemImage: "paperplane.fill") }
                                    .buttonStyle(NeonButton(fill: GameShow.hotPink, text: .white))
                            }
                            Button { model.saveToPhotos() } label: {
                                Label("SAVE", systemImage: "square.and.arrow.down")
                            }
                            .buttonStyle(NeonButton(fill: GameShow.neonCyan))
                            .disabled(model.encodedPNG == nil)
                        }
                    }
                }
            }

            // Message + passphrase — tight.
            GamePanel(tint: GameShow.neonLime) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        label("SECRET MESSAGE", tint: GameShow.magenta)
                        Text("\(model.bytesUsed)/\(model.bytesMax)")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundStyle(model.isOverBudget ? .red : GameShow.inkBlack.opacity(0.6))
                    }
                    TextField("Psst… whisper something", text: $model.message, axis: .vertical)
                        .lineLimit(1...2)
                        .font(.system(size: 13, weight: .heavy, design: .monospaced))
                        .padding(7)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(GameShow.inkBlack, lineWidth: 1.5))
                        .coachAnchor("mg.message")
                    HStack(spacing: 8) {
                        TextField("Passphrase (optional)", text: $model.passphrase)
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .autocorrectionDisabled().textInputAutocapitalization(.never)
                            .padding(7)
                            .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(GameShow.inkBlack, lineWidth: 1.5))
                        Button { model.generateKey() } label: {
                            Text("GENERATE")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundStyle(GameShow.inkBlack)
                                .padding(.horizontal, 10).padding(.vertical, 9)
                                .background(Capsule().fill(GameShow.neonYellow))
                                .overlay(Capsule().stroke(GameShow.inkBlack, lineWidth: 1.5))
                        }
                    }
                    .coachAnchor("mg.pass")
                }
            }

            // Cat picker — horizontal side-scroller, flexible height, in the middle.
            GamePanel(tint: GameShow.neonCyan) {
                VStack(alignment: .leading, spacing: 6) {
                    label("PICK A CAT!", tint: GameShow.hotPink)
                    GeometryReader { geo in
                        ScrollView(.horizontal, showsIndicators: false) {
                            // Lazy so only visible cats decode a thumbnail.
                            LazyHStack(spacing: 8) {
                                ForEach(model.catalog) { entry in
                                    Thumb(entry: entry,
                                          selected: model.selectedID == entry.id,
                                          height: geo.size.height)
                                        .onTapGesture { model.selectedID = entry.id }
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                }
            }
            .coachAnchor("mg.cats")

            // Primary action, full width, at the bottom.
            Button { model.embed() } label: {
                Label("EMBED!", systemImage: "wand.and.stars")
            }
            .buttonStyle(NeonButton(fill: GameShow.neonYellow))
            .disabled(model.selectedID == nil || model.message.isEmpty || model.isOverBudget)
            .coachAnchor("mg.embed")
        }
    }

    // MARK: Decode

    private var decodePane: some View {
        VStack(spacing: 12) {
            // Decoded message lands right at the top, under the mode buttons.
            if let msg = model.decodedMessage {
                GamePanel(tint: GameShow.neonYellow) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            label("MESSAGE!", tint: GameShow.hotPink)
                            if let guid = model.decodedGUID {
                                Text("🐱 \(guid.prefix(8))")
                                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(GameShow.inkBlack.opacity(0.5))
                            }
                        }
                        HStack {
                            Text(msg).font(.system(size: 13, weight: .heavy, design: .monospaced))
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

            GamePanel(tint: GameShow.neonCyan) {
                VStack(spacing: 10) {
                    label("DECODE A MEOWGRAM", tint: GameShow.hotPink)
                    // The MeowGram itself — full width, the panel resizes to it.
                    if let img = model.decodedImage {
                        // The decode animation lays over the MeowGram, so it's
                        // exactly the same size — the image gets "decoded".
                        Image(uiImage: img).resizable().aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .overlay { if model.isDecoding { MatrixDecodeView(label: "DECODING…") } }
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else if model.isDecoding {
                        MatrixDecodeView(label: "DECODING…")
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    // Bright callout so the passphrase field is unmissable.
                    VStack(alignment: .leading, spacing: 6) {
                        label("PASSPHRASE", tint: GameShow.hotPink)
                        TextField("Enter it if this MeowGram is locked", text: $model.passphrase)
                            .font(.system(size: 13, weight: .heavy, design: .monospaced))
                            .foregroundStyle(GameShow.inkBlack)
                            .autocorrectionDisabled().textInputAutocapitalization(.never)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(GameShow.inkBlack, lineWidth: 2))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 12).fill(GameShow.neonYellow))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(GameShow.inkBlack, lineWidth: 2))
                    .coachAnchor("mg.dpass")

                    // Primary action, full width, right under the passphrase.
                    Button { model.decodeLoaded() } label: {
                        Label("DECODE MEOWGRAM!", systemImage: "envelope.open.fill")
                    }
                    .buttonStyle(NeonButton(fill: GameShow.hotPink, text: .white))
                    .disabled(model.loadedData == nil || model.isDecoding)
                    .coachAnchor("mg.ddecode")

                    // Pick the source last, at the bottom.
                    HStack(spacing: 10) {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("PHOTOS", systemImage: "photo")
                        }
                        .buttonStyle(NeonButton(fill: GameShow.neonYellow))
                        Button { showFileImporter = true } label: { Label("FILES", systemImage: "folder") }
                            .buttonStyle(NeonButton(fill: GameShow.neonLime))
                        Button { model.pasteAndLoad() } label: { Label("PASTE", systemImage: "doc.on.clipboard") }
                            .buttonStyle(NeonButton(fill: GameShow.neonCyan))
                    }
                    .coachAnchor("mg.dsource")
                }
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

    private func banner(_ text: String, color: Color, text textColor: Color) -> some View {
        Text(text).font(.system(.footnote, design: .rounded).weight(.bold))
            .foregroundStyle(textColor).padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(color)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GameShow.inkBlack, lineWidth: 2)))
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
            img = await Task.detached { IOSThumbnailCache.shared.thumbnail(for: url) }.value
        }
    }
}
