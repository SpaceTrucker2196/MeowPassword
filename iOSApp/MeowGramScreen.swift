import SwiftUI
import UIKit
import ImageIO
import PhotosUI
import Photos
import UniformTypeIdentifiers
import MeowUI
import MeowGramKit
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
    @Published var isEmbedding = false

    // Decode
    @Published var decodedMessage: String?
    @Published var decodedGUID: String?
    @Published var decodedImage: UIImage?
    @Published var isDecoding = false

    @Published var status: String?
    @Published var errorText: String?

    var bytesUsed: Int { message.utf8.count }
    var bytesMax: Int { MeowGram.maxMessageBytes }
    var isOverBudget: Bool { bytesUsed > bytesMax }

    private var selectedEntry: MeowGramCatalog.Entry? { catalog.first { $0.id == selectedID } }

    func load() {
        guard catalog.isEmpty else { return }
        catalog = MeowGramCatalog.load()
        if selectedID == nil { selectedID = catalog.first?.id }
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
                self.status = "Embedded! Ready to share."
            } catch { self.errorText = describe(error) }
            self.isEmbedding = false
        }
    }

    func generateKey() {
        let key = MeowPass.meowKey()
        passphrase = key
        status = "Key: \(key) — read it aloud to your recipient."
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
                Task { @MainActor in self.errorText = "Photos access denied." }; return
            }
            PHPhotoLibrary.shared().performChanges {
                // Add the PNG bytes verbatim so the stego payload survives.
                let req = PHAssetCreationRequest.forAsset()
                req.addResource(with: .photo, data: png, options: nil)
            } completionHandler: { ok, err in
                Task { @MainActor in
                    if ok { self.status = "Saved to Photos (as PNG)." }
                    else { self.errorText = err?.localizedDescription ?? "Couldn't save." }
                }
            }
        }
    }

    // MARK: Decode

    func decode(data: Data, display: UIImage?) {
        mode = .decode
        isDecoding = true; errorText = nil; decodedMessage = nil; decodedGUID = nil
        decodedImage = display ?? UIImage(data: data)
        let pass = passphrase.isEmpty ? nil : passphrase
        Task {
            do {
                let (msg, guid): (String?, String?) = try await Task.detached {
                    let image = try ColorImageIO.readRGBImage(data: data)
                    let guid = MeowGram.readGUIDString(from: image)
                    let decoded = try MeowGram.readMessage(from: image, passphrase: pass)
                    return (decoded.message, decoded.guid ?? guid)
                }.value
                self.decodedMessage = msg
                self.decodedGUID = guid
            } catch { self.errorText = describe(error) }
            self.isDecoding = false
        }
    }

    func pasteAndDecode() {
        if let img = UIPasteboard.general.image, let data = img.pngData() {
            decode(data: data, display: img)
        } else if let data = UIPasteboard.general.data(forPasteboardType: UTType.png.identifier) {
            decode(data: data, display: UIImage(data: data))
        } else {
            mode = .decode
            errorText = "Nothing to paste — copy a MeowGram image first."
        }
    }

    private func describe(_ error: Error) -> String {
        (error as? CustomStringConvertible)?.description ?? error.localizedDescription
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
