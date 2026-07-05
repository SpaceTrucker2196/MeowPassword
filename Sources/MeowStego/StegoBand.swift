// Sources/MeowStego/StegoBand.swift

/// A contiguous slice of the mid-band zig-zag DCT positions that an encode /
/// decode pass is allowed to touch.
///
/// Two bands with non-overlapping `zigZagRange`s never write the same DCT
/// coefficient, so a payload embedded in one band survives a later,
/// independent embed into the other band. MeowGram uses this to keep a
/// per-image provenance GUID (the `.key` band) intact while users embed and
/// re-embed messages (the `.message` band).
public struct StegoBand: Equatable, Sendable {

    /// Zig-zag indices this band may use. Must lie within `0..<64`; in practice
    /// the mid-band (`10..<20`) is where imperceptibility and robustness trade
    /// off best.
    public let zigZagRange: Range<Int>

    public init(zigZagRange: Range<Int>) {
        self.zigZagRange = zigZagRange
    }

    /// The `(row, col)` coefficient positions this band covers, in zig-zag order.
    public var positions: [(Int, Int)] {
        Array(DCT8x8Provider.zigZagOrder[zigZagRange])
    }

    /// Number of coefficients this band embeds per 8×8 block.
    public var positionsPerBlock: Int { zigZagRange.count }

    /// Whether this band shares no coefficient with `other`.
    public func isDisjoint(from other: StegoBand) -> Bool {
        zigZagRange.upperBound <= other.zigZagRange.lowerBound ||
        other.zigZagRange.upperBound <= zigZagRange.lowerBound
    }

    /// All 10 mid-band positions — the historical behavior. Using `.full`
    /// keeps encode/decode bit-identical to versions before bands existed.
    public static let full    = StegoBand(zigZagRange: 10..<20)

    /// Provenance-GUID band: zig-zag 10–13 (4 coefficients per block).
    public static let key     = StegoBand(zigZagRange: 10..<14)

    /// User-message band: zig-zag 14–19 (6 coefficients per block). Disjoint
    /// from `.key`.
    public static let message = StegoBand(zigZagRange: 14..<20)
}
