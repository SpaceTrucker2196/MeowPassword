import Foundation

/// A tiny App-Group drop box for handing a to-be-decoded MeowGram image from
/// the "Decode MeowGram" share extension to the main app, which opens on its
/// decode screen with the image loaded.
public enum MeowGramInbox {
    public static let appGroup = "group.io.river.MeowPassword"

    private static func url() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
            .appendingPathComponent("decode-inbox.png")
    }

    /// True if the App Group container is available (entitlement present).
    public static var isAvailable: Bool { url() != nil }

    @discardableResult
    public static func write(_ data: Data) -> Bool {
        guard let url = url() else { return false }
        return (try? data.write(to: url)) != nil
    }

    public static func read() -> Data? {
        guard let url = url() else { return nil }
        return try? Data(contentsOf: url)
    }

    public static func clear() {
        if let url = url() { try? FileManager.default.removeItem(at: url) }
    }
}
