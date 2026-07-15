import SwiftUI
import UIKit
import ImageIO
import PhotosUI
import Photos
import UniformTypeIdentifiers
import MeowUI
import MeowGramKit
import MeowGramAssets
import MeowPassCore

@MainActor
final class MeowGramModeliOS: ObservableObject {
    enum Mode: String, CaseIterable { case compose = "COMPOSE", decode = "DECODE" }
    @Published var mode: Mode = .compose

    // Compose
    @Published var catalog: [MeowGramCatalog.Entry] = []
    @Published var selectedID: String?
    @Published var message = "" { didSet { invalidate() } }
    @Published var passphrase = "" { didSet { invalidate() } }
    @Published var previewImage: UIImage?
    @Published private(set) var encodedPNG: Data?
    @Published var isEmbedding = false {
        // Keep the screen awake while embedding too (same generating animation).
        didSet { UIApplication.shared.isIdleTimerDisabled = isDecoding || isEmbedding }
    }

    // Decode
    @Published var decodedMessage: String?
    @Published var decodedGUID: String?
    @Published var decodedImage: UIImage?
    @Published var isDecoding = false {
        // Keep the screen awake while decoding so it can't dim/lock mid-decode.
        didSet { UIApplication.shared.isIdleTimerDisabled = isDecoding || isEmbedding }
    }
    /// Raw bytes of the currently loaded MeowGram, kept so "DECODE MEOWGRAM!"
    /// can re-run with a passphrase after the image is picked.
    @Published private(set) var loadedData: Data?

    @Published var status: String?
    @Published var errorText: String?

    var bytesUsed: Int { message.utf8.count }
    var bytesMax: Int { MeowGram.maxMessageBytes }
    var isOverBudget: Bool { bytesUsed > bytesMax }

    private var selectedEntry: MeowGramCatalog.Entry? { catalog.first { $0.id == selectedID } }

    private var loadedSet: String?

    func load(set: String? = nil) {
        guard catalog.isEmpty || loadedSet != set else { return }
        loadedSet = set
        catalog = MeowGramCatalog.load(set: set)
        if selectedID == nil || !catalog.contains(where: { $0.id == selectedID }) {
            selectedID = catalog.first?.id
        }
    }

    private func invalidate() {
        if encodedPNG != nil { encodedPNG = nil; previewImage = nil; status = nil }
    }

    func embed() {
        guard let entry = selectedEntry, !message.isEmpty, !isOverBudget else { return }
        isEmbedding = true; errorText = nil; status = nil
        let path = entry.url.path, msg = message
        let pass = passphrase.isEmpty ? nil : passphrase
        Task {
            do {
                async let minShow: Void = Task.sleep(nanoseconds: 1_100_000_000)  // let the animation land
                let data: Data = try await Task.detached {
                    let image = try ColorImageIO.readRGBImage(path: path)
                    let stego = try MeowGram.embedMessage(msg, passphrase: pass, into: image)
                    return try ColorImageIO.pngData(stego)
                }.value
                try? await minShow
                self.encodedPNG = data
                self.previewImage = UIImage(data: data)
                self.status = String(localized: "Embedded! Ready to share.")
            } catch { self.errorText = describe(error) }
            self.isEmbedding = false
        }
    }

    func generateKey() {
        let key = MeowPass.meowKey()
        passphrase = key
        status = String(format: String(localized: "Key: %@ — read it aloud to your recipient."), key)
    }

    /// Write the embedded PNG to a temp file for ShareLink (lossless).
    func shareFileURL() -> URL? {
        guard let png = encodedPNG, let id = selectedID else { return nil }
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("MeowGrams", isDirectory: true)
        let url = dir.appendingPathComponent("MeowGram-\(id).png")
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try png.write(to: url)
            return url
        } catch { errorText = describe(error); return nil }
    }

    func saveToPhotos() {
        guard let png = encodedPNG else { return }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { st in
            guard st == .authorized || st == .limited else {
                Task { @MainActor in self.errorText = String(localized: "Photos access denied.") }; return
            }
            PHPhotoLibrary.shared().performChanges {
                // Add the PNG bytes verbatim so the stego payload survives.
                let req = PHAssetCreationRequest.forAsset()
                req.addResource(with: .photo, data: png, options: nil)
            } completionHandler: { ok, err in
                Task { @MainActor in
                    if ok { self.status = String(localized: "Saved to Photos (as PNG).") }
                    else { self.errorText = err?.localizedDescription ?? String(localized: "Couldn't save.") }
                }
            }
        }
    }

    // MARK: Decode

    func decode(data: Data, display: UIImage?) {
        mode = .decode
        loadedData = data
        isDecoding = true; errorText = nil; decodedMessage = nil; decodedGUID = nil
        decodedImage = display ?? UIImage(data: data)
        let pass = passphrase.isEmpty ? nil : passphrase
        Task {
            do {
                async let minShow: Void = Task.sleep(nanoseconds: 1_100_000_000)  // let the animation land
                let (msg, guid): (String?, String?) = try await Task.detached {
                    let image = try ColorImageIO.readRGBImage(data: data)
                    let guid = MeowGram.readGUIDString(from: image)
                    let decoded = try MeowGram.readMessage(from: image, passphrase: pass)
                    return (decoded.message, decoded.guid ?? guid)
                }.value
                try? await minShow
                self.decodedMessage = msg
                self.decodedGUID = guid
            } catch { self.errorText = describe(error) }
            self.isDecoding = false
        }
    }

    /// Load a MeowGram image WITHOUT decoding — the picker actions just stage
    /// the image so the user can type a passphrase before tapping "DECODE
    /// MEOWGRAM!". Clears any prior result.
    func load(data: Data, display: UIImage?) {
        mode = .decode
        loadedData = data
        decodedImage = display ?? UIImage(data: data)
        decodedMessage = nil; decodedGUID = nil; errorText = nil; isDecoding = false
    }

    /// Decode the already-loaded MeowGram with the current passphrase —
    /// the action behind the "DECODE MEOWGRAM!" button.
    func decodeLoaded() {
        guard let data = loadedData else { return }
        decode(data: data, display: decodedImage)
    }

    func pasteAndLoad() {
        if let img = UIPasteboard.general.image, let data = img.pngData() {
            load(data: data, display: img)
        } else if let data = UIPasteboard.general.data(forPasteboardType: UTType.png.identifier) {
            load(data: data, display: UIImage(data: data))
        } else {
            mode = .decode
            errorText = String(localized: "Nothing to paste — copy a MeowGram image first.")
        }
    }

    private func describe(_ error: Error) -> String {
        if let mg = error as? MeowGram.MGError {
            switch mg {
            case .notAMeowGram:   return String(localized: "This image isn't a MeowGram (no provenance key found).")
            case .noMessage:      return String(localized: "No hidden message found in this MeowGram.")
            case .wrongPassphrase: return String(localized: "Wrong passphrase — the message couldn't be unlocked.")
            case .messageTooLong(let n): return String(format: String(localized: "Message too long (%1$d bytes; max %2$d)."), n, MeowGram.maxMessageBytes)
            case .malformed:      return String(localized: "The embedded data is malformed.")
            }
        }
        return (error as? CustomStringConvertible)?.description ?? error.localizedDescription
    }
}

/// iOS thumbnail cache (UIImage), so the 100-cell grid stays smooth.
final class IOSThumbnailCache {
    static let shared = IOSThumbnailCache()
    private let cache = NSCache<NSURL, UIImage>()
    func thumbnail(for url: URL, maxPixel: CGFloat = 220) -> UIImage? {
        if let hit = cache.object(forKey: url as NSURL) { return hit }
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceThumbnailMaxPixelSize: maxPixel,
                  kCGImageSourceCreateThumbnailWithTransform: true
              ] as CFDictionary) else { return nil }
        let img = UIImage(cgImage: cg)
        cache.setObject(img, forKey: url as NSURL)
        return img
    }
}
