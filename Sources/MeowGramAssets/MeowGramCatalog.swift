// Sources/MeowGramKit/MeowGramCatalog.swift

#if canImport(CoreGraphics)
import Foundation

/// The keyed meowgram images bundled with MeowGramAssets. The default set
/// lives in `Meowgrams/`; themes may bundle their own set in a sibling
/// `Meowgrams-<Set>/` directory (e.g. `Meowgrams-Soviet` for Kremlin
/// Cartoon). Both apps and the iMessage extension enumerate cats through
/// here via `Bundle.module`. Thumbnail rendering (NSImage / UIImage) stays
/// in each app's UI layer. The wire format is untouched — any keyed PNG
/// from any set embeds and decodes identically.
public enum MeowGramCatalog {

    public struct Entry: Identifiable, Hashable {
        public let id: String    // e.g. "meowgram-42"
        public let url: URL      // bundled keyed PNG
        public init(id: String, url: URL) { self.id = id; self.url = url }
    }

    /// Enumerate a set's keyed PNGs, natural-sorted by name. `set` names a
    /// `Meowgrams-<set>` bundle directory (a theme's `meowgramSet` token);
    /// nil — or a set with no bundled images — falls back to the default.
    public static func load(set: String? = nil) -> [Entry] {
        if let set, !set.isEmpty {
            let themed = entries(in: "Meowgrams-\(set)")
            if !themed.isEmpty { return themed }
        }
        return entries(in: "Meowgrams")
    }

    private static func entries(in subdirectory: String) -> [Entry] {
        let urls = Bundle.module.urls(forResourcesWithExtension: "png", subdirectory: subdirectory) ?? []
        return urls
            .map { Entry(id: $0.deletingPathExtension().lastPathComponent, url: $0) }
            .sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }
    }
}
#endif
