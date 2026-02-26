// Sources/MeowStego/PRNG.swift

/// Deterministic pseudorandom number generator used to scatter DCT coefficient
/// positions during steganographic embedding and extraction.
///
/// Uses xorshift64 seeded via FNV-1a hash of the supplied watermark key so that
/// encoder and decoder produce identical index sequences for the same key.
public struct MeowPRNG {
    private var state: UInt64

    /// Initialise the PRNG from raw key bytes.
    public init(key: [UInt8]) {
        var h: UInt64 = 0xcbf29ce484222325  // FNV-1a offset basis
        for byte in key {
            h ^= UInt64(byte)
            h = h &* 0x100000001b3          // FNV prime
        }
        state = h == 0 ? 0x5eed_5eed_5eed_5eed : h
    }

    /// Initialise the PRNG from a lower-case hex string (e.g. `"001122aabb"`).
    /// Returns `nil` if the string has an odd length or contains non-hex digits.
    public init?(hexKey: String) {
        guard hexKey.count % 2 == 0 else { return nil }
        var bytes: [UInt8] = []
        var idx = hexKey.startIndex
        while idx < hexKey.endIndex {
            let next = hexKey.index(idx, offsetBy: 2)
            guard let byte = UInt8(hexKey[idx..<next], radix: 16) else { return nil }
            bytes.append(byte)
            idx = next
        }
        self.init(key: bytes)
    }

    /// Returns the next 64-bit pseudorandom value (xorshift64).
    public mutating func nextUInt64() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }

    /// Returns a uniformly distributed random integer in `range`.
    public mutating func nextInt(in range: Range<Int>) -> Int {
        precondition(!range.isEmpty)
        return range.lowerBound + Int(nextUInt64() % UInt64(range.count))
    }

    /// Generates a shuffled permutation of `0..<count` using Fisher-Yates.
    /// Calling this with the same key always produces the same permutation.
    public mutating func shuffled(_ count: Int) -> [Int] {
        var arr = Array(0..<count)
        for i in stride(from: count - 1, through: 1, by: -1) {
            let j = nextInt(in: 0..<(i + 1))
            arr.swapAt(i, j)
        }
        return arr
    }
}
