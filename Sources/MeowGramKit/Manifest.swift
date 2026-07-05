// Sources/MeowGramKit/Manifest.swift

import Foundation

/// The git-crypted record mapping each shipped keyed image to its provenance
/// GUID. Kept encrypted at rest so the set of valid GUIDs can't be read out of
/// the repo and used to forge authentic-looking meowgrams.
public struct MeowGramManifest: Codable, Equatable {
    public var version: Int
    public var created: String            // ISO-8601 UTC
    public var keyBand: KeyBand
    public var geometry: Geometry
    public var images: [Entry]

    public struct KeyBand: Codable, Equatable {
        public var zigZag: [Int]          // [lowerBound, upperBound]
        public var qimStep: Double
        public init(zigZag: [Int], qimStep: Double) {
            self.zigZag = zigZag; self.qimStep = qimStep
        }
    }

    public struct Geometry: Codable, Equatable {
        public var width: Int
        public var height: Int
        public init(width: Int, height: Int) {
            self.width = width; self.height = height
        }
    }

    public struct Entry: Codable, Equatable {
        public var file: String           // e.g. "meowgram-01.png"
        public var source: String         // e.g. "meowgram-01.jpg"
        public var guid: String           // uppercase UUID string
        public var sha256: String         // hex of the keyed PNG
        public init(file: String, source: String, guid: String, sha256: String) {
            self.file = file; self.source = source; self.guid = guid; self.sha256 = sha256
        }
    }

    public init(version: Int, created: String, keyBand: KeyBand,
                geometry: Geometry, images: [Entry]) {
        self.version = version
        self.created = created
        self.keyBand = keyBand
        self.geometry = geometry
        self.images = images
    }

    public static func load(path: String) throws -> MeowGramManifest {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(MeowGramManifest.self, from: data)
    }

    public func write(path: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        try data.write(to: URL(fileURLWithPath: path))
    }

    /// Look up whether a decoded GUID is a known, authentic meowgram.
    public func contains(guid: String) -> Bool {
        images.contains { $0.guid.caseInsensitiveCompare(guid) == .orderedSame }
    }
}
