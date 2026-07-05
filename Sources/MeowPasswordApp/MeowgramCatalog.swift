import Foundation
import AppKit
import ImageIO

/// The set of keyed meowgram images bundled with the app, plus a lazy
/// thumbnail cache for the picker grid.
enum MeowgramCatalog {

    struct Entry: Identifiable, Hashable {
        let id: String     // e.g. "meowgram-42"
        let url: URL       // bundled keyed PNG
    }

    /// Enumerate the bundled `Meowgrams/*.png`, natural-sorted. Checks
    /// `Bundle.main` (assembled .app) first, then `Bundle.module` (`swift run`).
    static func load() -> [Entry] {
        let urls =
            Bundle.main.urls(forResourcesWithExtension: "png", subdirectory: "Meowgrams")
            ?? Bundle.module.urls(forResourcesWithExtension: "png", subdirectory: "Meowgrams")
            ?? []
        return urls
            .map { Entry(id: $0.deletingPathExtension().lastPathComponent, url: $0) }
            .sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
    }
}

/// Downscaled thumbnails generated on demand and cached, so a 100-cell grid
/// doesn't decode full-size PNGs while scrolling.
final class ThumbnailCache {
    static let shared = ThumbnailCache()
    private let cache = NSCache<NSURL, NSImage>()

    func thumbnail(for url: URL, maxPixel: CGFloat = 220) -> NSImage? {
        if let hit = cache.object(forKey: url as NSURL) { return hit }
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceThumbnailMaxPixelSize: maxPixel,
                  kCGImageSourceCreateThumbnailWithTransform: true
              ] as CFDictionary) else { return nil }
        let img = NSImage(cgImage: cg, size: .zero)
        cache.setObject(img, forKey: url as NSURL)
        return img
    }
}
