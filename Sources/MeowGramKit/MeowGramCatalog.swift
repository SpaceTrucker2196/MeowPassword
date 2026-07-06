// Sources/MeowGramKit/MeowGramCatalog.swift

#if canImport(CoreGraphics)
import Foundation

/// The set of keyed meowgram images bundled with MeowGramKit (`Meowgrams/*.png`
/// resource). Both the macOS and iOS apps enumerate the cats through here via
/// `Bundle.module`, so there is one shared image set. Thumbnail rendering
/// (NSImage / UIImage) stays in each app's UI layer.
public enum MeowGramCatalog {

    public struct Entry: Identifiable, Hashable {
        public let id: String    // e.g. "meowgram-42"
        public let url: URL      // bundled keyed PNG
        public init(id: String, url: URL) { self.id = id; self.url = url }
    }

    /// Enumerate the bundled keyed PNGs, natural-sorted by name.
    public static func load() -> [Entry] {
        let urls = Bundle.module.urls(forResourcesWithExtension: "png", subdirectory: "Meowgrams") ?? []
        return urls
            .map { Entry(id: $0.deletingPathExtension().lastPathComponent, url: $0) }
            .sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
    }
}
#endif
