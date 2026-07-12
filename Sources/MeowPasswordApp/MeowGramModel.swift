import Foundation
import SwiftUI
import AppKit
import UniformTypeIdentifiers
import MeowGramKit
import MeowPassCore

/// State for the MeowGram window: compose (pick cat → message → embed → send)
/// and decode (drop an image → reveal message).
@MainActor
final class MeowGramModel: ObservableObject {

    enum Mode: String, CaseIterable { case compose = "COMPOSE", decode = "DECODE" }

    @Published var mode: Mode = .compose

    // Compose inputs
    @Published var catalog: [MeowgramCatalog.Entry] = []
    @Published var selectedID: MeowgramCatalog.Entry.ID?
    @Published var message: String = "" { didSet { invalidateEmbedIfStale() } }
    @Published var passphrase: String = "" { didSet { invalidateEmbedIfStale() } }

    // Compose outputs
    @Published var previewImage: NSImage?
    @Published private(set) var encodedPNG: Data?
    @Published var isEmbedding = false

    // Decode
    @Published var isDropTargeted = false
    @Published var decodedMessage: String?
    @Published var decodedImage: NSImage?
    @Published var decodedGUID: String?
    @Published var isDecoding = false
    /// Raw bytes of the staged MeowGram, kept so "DECODE MEOWGRAM!" can run
    /// with a passphrase after the image is dropped / pasted / opened.
    @Published private(set) var loadedData: Data?
    private var loadedLossy = false

    // Shared
    @Published var lastError: String?
    @Published var statusText: String?

    var payloadBytesUsed: Int { message.utf8.count }
    var payloadBytesMax: Int { MeowGram.maxMessageBytes }
    var isOverBudget: Bool { payloadBytesUsed > payloadBytesMax }

    private var selectedEntry: MeowgramCatalog.Entry? {
        catalog.first { $0.id == selectedID }
    }

    func loadCatalog() {
        guard catalog.isEmpty else { return }
        let entries = MeowgramCatalog.load()
        self.catalog = entries
        if selectedID == nil { selectedID = entries.first?.id }
        cleanupOldTempFiles()
    }

    // MARK: - Compose

    /// Fill the passphrase with a voice-friendly `catname-catname-catname` key
    /// from the embedded cat-name database (via the bundled `meowpass` CLI).
    func generatePassphrase() {
        let key = MeowPass.meowKey()
        passphrase = key
        statusText = "Key: \(key) — read it aloud to your recipient."
    }

    func embed() {
        guard let entry = selectedEntry else { lastError = "Pick a cat first!"; return }
        guard !message.isEmpty else { lastError = "Type a message first!"; return }
        guard !isOverBudget else {
            lastError = "Message is too long (\(payloadBytesUsed)/\(payloadBytesMax) bytes)."; return
        }
        let path = entry.url.path
        let msg = message
        let pass = passphrase.isEmpty ? nil : passphrase
        isEmbedding = true; lastError = nil; statusText = nil

        Task.detached(priority: .userInitiated) {
            do {
                async let minShow: Void = Task.sleep(nanoseconds: 1_100_000_000)  // let the animation land
                let image = try ColorImageIO.readRGBImage(path: path)
                let stego = try MeowGram.embedMessage(msg, passphrase: pass, into: image)
                let data = try ColorImageIO.pngData(stego)
                let nsImage = NSImage(data: data)
                try? await minShow
                await MainActor.run {
                    self.encodedPNG = data
                    self.previewImage = nsImage
                    self.isEmbedding = false
                    self.statusText = "Embedded! Ready to send."
                }
            } catch {
                let desc = (error as? CustomStringConvertible)?.description ?? error.localizedDescription
                await MainActor.run { self.lastError = desc; self.isEmbedding = false }
            }
        }
    }

    /// Any change to inputs invalidates a prior embed so SEND/SAVE can't ship
    /// something other than what's previewed.
    private func invalidateEmbedIfStale() {
        if encodedPNG != nil {
            encodedPNG = nil
            previewImage = nil
            statusText = nil
        }
    }

    /// Message body shared with both the Mail and Messages compose paths.
    private var shareBody: String {
        "I sent you a MeowGram! 🐱 Drop this PNG into MeowPassword to decode the hidden "
      + "message. Keep it a PNG — don't screenshot or convert it, or the message is lost."
    }

    /// Write the embedded PNG to a temp file (verbatim — never re-encode) for
    /// attaching to Mail / Messages.
    private func stageTempPNG() -> URL? {
        guard let png = encodedPNG, let id = selectedID else { return nil }
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowGrams", isDirectory: true)
        let stamp = Int(Date().timeIntervalSince1970)
        let fileURL = dir.appendingPathComponent("MeowGram-\(id)-\(stamp).png")
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try png.write(to: fileURL)
            return fileURL
        } catch {
            lastError = "Couldn't stage the attachment: \(error.localizedDescription)"
            return nil
        }
    }

    func sendViaMail() {
        guard let fileURL = stageTempPNG() else { return }
        let items: [Any] = [shareBody, fileURL as NSURL]
        guard let service = NSSharingService(named: .composeEmail),
              service.canPerform(withItems: items) else {
            statusText = "No Mail account is set up — saving the PNG instead."
            savePNG()
            return
        }
        service.subject = "A MeowGram for you 🐱"
        service.perform(withItems: items)
        statusText = "Handed off to Mail — hit send!"
    }

    /// Send the MeowGram via the Messages app (iMessage) with the PNG attached.
    func sendViaMessages() {
        guard let fileURL = stageTempPNG() else { return }
        let items: [Any] = [shareBody, fileURL as NSURL]
        guard let service = NSSharingService(named: .composeMessage),
              service.canPerform(withItems: items) else {
            statusText = "Messages isn't available — saving the PNG instead."
            savePNG()
            return
        }
        service.perform(withItems: items)
        statusText = "Handed off to Messages — hit send!"
    }

    /// Copy the embedded MeowGram to the clipboard — as a real PNG file (so
    /// pasting into Mail / Messages / Finder attaches lossless bytes) and as
    /// image data (for image-accepting targets). Warn that image-paste targets
    /// may re-encode and destroy the payload.
    func copyToPasteboard() {
        guard let png = encodedPNG, let id = selectedID else { return }
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MeowGrams", isDirectory: true)
        let fileURL = dir.appendingPathComponent("MeowGram-\(id).png")
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try png.write(to: fileURL)   // verbatim PNG
        } catch {
            lastError = "Couldn't stage the copy: \(error.localizedDescription)"; return
        }
        let pb = NSPasteboard.general
        pb.clearContents()
        let item = NSPasteboardItem()
        item.setData(png, forType: .png)
        item.setString(fileURL.absoluteString, forType: .fileURL)
        pb.writeObjects([item])
        statusText = "Copied! Paste it as a PNG — image-paste targets may re-encode it."
    }

    /// Decode a MeowGram straight from the clipboard: a copied PNG file if
    /// present (lossless), otherwise image data on the pasteboard.
    func pasteAndLoad() {
        mode = .decode
        let pb = NSPasteboard.general
        if let urls = pb.readObjects(forClasses: [NSURL.self],
                                     options: [.urlReadingFileURLsOnly: true]) as? [URL],
           let u = urls.first {
            load(fileURL: u)
            return
        }
        if let data = pb.data(forType: .png) ?? pb.data(forType: .tiff),
           let img = NSImage(data: data) {
            load(image: img)
            return
        }
        lastError = "Nothing to paste — copy a MeowGram image or PNG file first."
    }

    /// Open a MeowGram from disk (matches iOS "FILES") — loads, doesn't decode.
    func openAndLoad() {
        mode = .decode
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .image]
        panel.allowsMultipleSelection = false
        panel.begin { resp in
            guard resp == .OK, let url = panel.url else { return }
            Task { @MainActor in self.load(fileURL: url) }
        }
    }

    func savePNG() {
        guard let png = encodedPNG, let id = selectedID else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "MeowGram-\(id).png"
        panel.begin { resp in
            guard resp == .OK, let url = panel.url else { return }
            do {
                try png.write(to: url)
                NSWorkspace.shared.activateFileViewerSelecting([url])
                Task { @MainActor in self.statusText = "Saved \(url.lastPathComponent)" }
            } catch {
                Task { @MainActor in self.lastError = error.localizedDescription }
            }
        }
    }

    // MARK: - Decode

    func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: {
            $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier)
        }) else { return false }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL? =
                (item as? URL) ??
                (item as? Data).flatMap { URL(dataRepresentation: $0, relativeTo: nil) }
            guard let url else { return }
            Task { @MainActor in
                self.mode = .decode
                self.load(fileURL: url)
            }
        }
        return true
    }

    // MARK: Deferred load → decode (mirrors iOS: stage the image, then the
    // "DECODE MEOWGRAM!" button decodes it with the current passphrase).

    func load(fileURL: URL) {
        guard let type = UTType(filenameExtension: fileURL.pathExtension),
              type.conforms(to: .image) else {
            lastError = "That doesn't look like an image. Drop a MeowGram PNG."
            return
        }
        let accessed = fileURL.startAccessingSecurityScopedResource()
        defer { if accessed { fileURL.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: fileURL) else {
            lastError = "Couldn't read that file."
            return
        }
        loadedLossy = ["jpg", "jpeg", "heic", "heif", "webp"].contains(fileURL.pathExtension.lowercased())
        stage(data: data, display: NSImage(contentsOf: fileURL))
    }

    func load(image nsImage: NSImage) {
        guard let tiff = nsImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            lastError = "Couldn't read that pasted image."
            return
        }
        loadedLossy = false
        stage(data: png, display: nsImage)
    }

    private func stage(data: Data, display: NSImage?) {
        mode = .decode
        loadedData = data
        decodedImage = display
        decodedMessage = nil; decodedGUID = nil; lastError = nil; statusText = nil
        isDecoding = false
    }

    /// Decode the staged MeowGram with the current passphrase — the action
    /// behind the "DECODE MEOWGRAM!" button. Keeps the image on screen so the
    /// decode animation lays over it.
    func decodeLoaded() {
        guard let data = loadedData else { return }
        isDecoding = true
        lastError = nil; decodedMessage = nil; decodedGUID = nil; statusText = nil
        let pass = passphrase.isEmpty ? nil : passphrase
        let display = decodedImage
        let lossy = loadedLossy
        Task.detached(priority: .userInitiated) {
            // In-memory decode is near-instant; hold isDecoding long enough for
            // the digital-rain animation to actually land (mirrors iOS).
            async let minShow: Void = Task.sleep(nanoseconds: 1_100_000_000)
            do {
                let image = try ColorImageIO.readRGBImage(data: data)
                try? await minShow
                await self.finishDecode(image: image, display: display, lossy: lossy, pass: pass)
            } catch {
                try? await minShow
                await self.failDecode(error, display: display, lossy: lossy)
            }
        }
    }

    /// Runs off the detached task; report authenticity even when there is no
    /// message, so a bare keyed master reads as "authentic, no message".
    private func finishDecode(
        image: ColorImageIO.RGBImage, display: NSImage?, lossy: Bool, pass: String?
    ) async {
        let guid = MeowGram.readGUIDString(from: image)
        var message: String?
        var errorText: String?
        do {
            message = try MeowGram.readMessage(from: image, passphrase: pass).message
        } catch {
            let desc = (error as? CustomStringConvertible)?.description ?? error.localizedDescription
            if guid != nil {
                // Authentic but message missing or locked — friendlier phrasing.
                errorText = desc
            } else {
                errorText = lossy
                    ? "No MeowGram here — JPEG/HEIC re-compression usually destroys them. "
                      + "Ask the sender for the original PNG."
                    : desc
            }
        }
        await MainActor.run {
            self.decodedImage = display
            self.decodedGUID = guid
            self.decodedMessage = message
            self.lastError = (message == nil) ? errorText : nil
            self.isDecoding = false
        }
    }

    private func failDecode(_ error: Error, display: NSImage?, lossy: Bool) async {
        let desc = (error as? CustomStringConvertible)?.description ?? error.localizedDescription
        await MainActor.run {
            self.decodedImage = display
            self.lastError = lossy
                ? "Couldn't read that image as a MeowGram (\(desc))."
                : desc
            self.isDecoding = false
        }
    }

    // MARK: - Housekeeping

    /// Delete staged mail attachments older than a day (Mail reads them async,
    /// so we don't delete right after handing off).
    private func cleanupOldTempFiles() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("MeowGrams")
        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }
        let cutoff = Date().addingTimeInterval(-86_400)
        for url in urls {
            if let mod = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
               mod < cutoff {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}
