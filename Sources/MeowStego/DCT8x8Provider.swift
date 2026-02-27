// Sources/MeowStego/DCT8x8Provider.swift

import Foundation

/// Two-dimensional Discrete Cosine Transform (Type-II) and its inverse for
/// 8×8 pixel blocks, as used in JPEG/MPEG processing and DCT-domain
/// steganographic watermarking.
///
/// Input pixels are assumed to be centre-shifted by −128 before calling `dct`.
public enum DCT8x8Provider {

    static let N = 8

    // Precomputed cosine table: cosTable[u][x] = cos((2x+1)·u·π / (2N))
    private static let cosTable: [[Double]] = {
        var t = [[Double]](repeating: [Double](repeating: 0, count: N), count: N)
        for u in 0..<N {
            for x in 0..<N {
                t[u][x] = cos(Double(2 * x + 1) * Double(u) * .pi / Double(2 * N))
            }
        }
        return t
    }()

    private static func alpha(_ n: Int) -> Double {
        n == 0 ? 1.0 / sqrt(Double(N)) : sqrt(2.0 / Double(N))
    }

    // MARK: – Forward DCT

    /// Forward 2-D DCT of an 8×8 block.
    ///
    /// - Parameter block: 64 `Float` values in row-major order.
    ///   Values should be centre-shifted (subtract 128 from raw luma bytes).
    /// - Returns: 64 DCT coefficients in row-major order.
    public static func dct(_ block: [Float]) -> [Float] {
        assert(block.count == 64)
        var result = [Float](repeating: 0, count: 64)
        for u in 0..<N {
            let au = alpha(u)
            for v in 0..<N {
                let av = alpha(v)
                var sum = 0.0
                for x in 0..<N {
                    let cx = cosTable[u][x]
                    for y in 0..<N {
                        sum += Double(block[x * N + y]) * cx * cosTable[v][y]
                    }
                }
                result[u * N + v] = Float(au * av * sum)
            }
        }
        return result
    }

    // MARK: – Inverse DCT

    /// Inverse 2-D DCT of an 8×8 coefficient block.
    ///
    /// - Parameter coeffs: 64 DCT coefficients in row-major order.
    /// - Returns: 64 pixel values (still centre-shifted; add 128 to get 0–255).
    public static func idct(_ coeffs: [Float]) -> [Float] {
        assert(coeffs.count == 64)
        var result = [Float](repeating: 0, count: 64)
        for x in 0..<N {
            for y in 0..<N {
                var sum = 0.0
                for u in 0..<N {
                    let au = alpha(u)
                    let cx = cosTable[u][x]
                    for v in 0..<N {
                        sum += au * alpha(v) * Double(coeffs[u * N + v]) * cx * cosTable[v][y]
                    }
                }
                result[x * N + y] = Float(sum)
            }
        }
        return result
    }

    // MARK: – Zig-zag scan order

    /// All 64 (row, col) pairs in the standard JPEG zig-zag order.
    public static let zigZagOrder: [(Int, Int)] = {
        var order = [(Int, Int)]()
        order.reserveCapacity(64)
        var row = 0, col = 0
        var goingUp = true
        while order.count < 64 {
            order.append((row, col))
            if goingUp {
                if col == N - 1 {
                    row += 1; goingUp = false
                } else if row == 0 {
                    col += 1; goingUp = false
                } else {
                    row -= 1; col += 1
                }
            } else {
                if row == N - 1 {
                    col += 1; goingUp = true
                } else if col == 0 {
                    row += 1; goingUp = true
                } else {
                    row += 1; col -= 1
                }
            }
        }
        return order
    }()

    /// Mid-band coefficient positions (zig-zag indices 10–19).
    ///
    /// These AC coefficients offer a good trade-off between visual
    /// imperceptibility and robustness to moderate JPEG compression.
    public static let midBandPositions: [(Int, Int)] = Array(zigZagOrder[10..<20])
}
