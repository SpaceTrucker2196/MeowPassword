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

    var body: some View {
        ZStack {
            GameShow.bg.ignoresSafeArea()
            SparkleField(count: 50).ignoresSafeArea()
            VStack(spacing: 10) {
                topBar
                // Compose fills the screen without scrolling (the cat picker
                // scrolls sideways instead); decode may scroll for the result.
                Group {
                    if model.mode == .compose {
                        composePane
                    } else {
                        ScrollView { decodePane }
                    }
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
            // and decode the handed-off image immediately.
            if let data = decodeOnOpen {
                model.mode = .decode
                model.decode(data: data, display: UIImage(data: data))
            }
        }
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    model.decode(data: data, display: UIImage(data: data))
                }
            }
        }
        .fileImporter(isPresented: $showFileImporter,
                      allowedContentTypes: [.png, .image], allowsMultipleSelection: false) { result in
            if case .success(let urls) = result, let url = urls.first {
                let ok = url.startAccessingSecurityScopedResource()
                defer { if ok { url.stopAccessingSecurityScopedResource() } }
                if let data = try? Data(contentsOf: url) {
                    model.decode(data: data, display: UIImage(data: data))
                }
            }
        }
    }

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                Button { onClose() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(GameShow.inkBlack)
                        .padding(8)
                        .background(Circle().fill(GameShow.paperWhite))
                        .overlay(Circle().stroke(GameShow.inkBlack, lineWidth: 2))
                }
                Text("MEOWGRAM")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: GameShow.inkBlack, radius: 0, x: 2, y: 2)
                Spacer()
            }
            HStack(spacing: 12) {
                ForEach(MeowGramModeliOS.Mode.allCases, id: \.self) { m in
                    Button { model.mode = m } label: {
                        Label(m.rawValue, systemImage: m == .compose ? "square.and.pencil" : "eye.fill")
                    }
                    .buttonStyle(NeonButton(fill: model.mode == m ? GameShow.neonYellow : GameShow.paperWhite))
                }
            }
        }
    }

    // MARK: Compose

    private var composePane: some View {
        VStack(spacing: 10) {
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
                    .frame(minHeight: 90)
                }
            }
            .frame(maxHeight: .infinity)

            // Preview + actions — compact. While embedding, the whole panel
            // becomes the generating animation.
            GamePanel(tint: GameShow.neonYellow) {
                if model.isEmbedding {
                    EmbedGeneratingView()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    VStack(spacing: 8) {
                        HStack(spacing: 10) {
                            if let img = model.previewImage {
                                Image(uiImage: img).resizable().aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: 90, maxHeight: 112)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                RoundedRectangle(cornerRadius: 8).fill(GameShow.inkBlack.opacity(0.1))
                                    .frame(width: 90, height: 112)
                                    .overlay(Image(systemName: "photo").foregroundStyle(GameShow.inkBlack.opacity(0.3)))
                            }
                            Button { model.embed() } label: {
                                Label("EMBED!", systemImage: "wand.and.stars")
                            }
                            .buttonStyle(NeonButton(fill: GameShow.neonYellow))
                            .disabled(model.selectedID == nil || model.message.isEmpty || model.isOverBudget)
                        }
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
        }
    }

    // MARK: Decode

    private var decodePane: some View {
        VStack(spacing: 12) {
            GamePanel(tint: GameShow.neonCyan) {
                VStack(spacing: 10) {
                    label("DECODE A MEOWGRAM", tint: GameShow.hotPink)
                    if model.isDecoding { ProgressView() }
                    if let img = model.decodedImage {
                        Image(uiImage: img).resizable().aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 200).clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    HStack(spacing: 10) {
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            Label("PHOTOS", systemImage: "photo")
                        }
                        .buttonStyle(NeonButton(fill: GameShow.neonYellow))
                        Button { showFileImporter = true } label: { Label("FILES", systemImage: "folder") }
                            .buttonStyle(NeonButton(fill: GameShow.neonLime))
                        Button { model.pasteAndDecode() } label: { Label("PASTE", systemImage: "doc.on.clipboard") }
                            .buttonStyle(NeonButton(fill: GameShow.neonCyan))
                    }
                    TextField("Passphrase (if locked)", text: $model.passphrase)
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .autocorrectionDisabled().textInputAutocapitalization(.never)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(GameShow.inkBlack, lineWidth: 1.5))
                }
            }
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
