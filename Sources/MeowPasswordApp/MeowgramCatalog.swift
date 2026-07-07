import Foundation
import AppKit
import ImageIO
import MeowGramAssets

/// The bundled keyed meowgrams now live in the shared `MeowGramKit` resource,
/// so the app just re-exports the shared catalog. Thumbnail rendering
/// (`NSImage`) stays app-side.
enum MeowgramCatalog {
    typealias Entry = MeowGramCatalog.Entry
    static func load() -> [Entry] { MeowGramCatalog.load() }
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
