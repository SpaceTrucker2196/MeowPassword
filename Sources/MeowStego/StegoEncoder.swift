// Sources/MeowStego/StegoEncoder.swift

// MARK: – Errors

/// Errors that can be thrown during steganographic encode / decode operations.
public enum StegoError: Error, CustomStringConvertible {
    case insufficientCapacity(needed: Int, available: Int)
    case payloadTooLarge(size: Int, maxSize: Int)
    case invalidImageDimensions
    case syncNotFound
    case eccDecodingFailed
    case malformedStream

    public var description: String {
        switch self {
        case .insufficientCapacity(let n, let a):
            return "Insufficient capacity: need \(n) bits but image only holds \(a)"
        case .payloadTooLarge(let s, let m):
            return "Payload too large: \(s) bytes exceeds \(m) byte limit"
        case .invalidImageDimensions:
            return "Image dimensions must be multiples of 8"
        case .syncNotFound:
            return "Sync preamble not found in image"
        case .eccDecodingFailed:
            return "ECC decoding failed — too many errors to correct"
        case .malformedStream:
            return "Malformed embedded stream (bad length field)"
        }
    }
}

// MARK: – QIM primitives  (from the issue spec, §Embedding Algorithm)

/// Embed one bit into a DCT coefficient using dithered Quantisation Index
/// Modulation (QIM).
///
/// - Parameters:
///   - c:    Original DCT coefficient.
///   - bit:  Bit to embed (0 or 1).
///   - step: QIM quantisation step size.
/// - Returns: Modified coefficient carrying the embedded bit.
@inline(__always)
func qimEmbed(_ c: Float, bit: Int, step: Float) -> Float {
    let d: Float = bit == 0 ? -step / 4 : step / 4
    return step * ((c - d) / step).rounded() + d
}

/// Extract one bit from a DCT coefficient using dithered QIM.
///
/// - Parameters:
///   - c:    Coefficient to read.
///   - step: QIM quantisation step size (must match the encoder).
/// - Returns: Extracted bit (0 or 1).
@inline(__always)
func qimExtract(_ c: Float, step: Float) -> Int {
    let d0: Float = -step / 4
    let d1: Float =  step / 4
    let e0 = abs(c - (step * ((c - d0) / step).rounded() + d0))
    let e1 = abs(c - (step * ((c - d1) / step).rounded() + d1))
    return e1 < e0 ? 1 : 0
}

// MARK: – Encoder

/// Encodes a short-lived authentication payload (≤ 512 bytes) into the luma
/// channel of a grayscale image using DCT-domain QIM steganography with
/// Reed–Solomon ECC.
///
/// ## Wire format (bit stream)
/// ```
/// [32-bit sync word 0xCAFEBABE]
/// [32-bit big-endian ECC data length in bytes]
/// [ECC-encoded payload bytes × 8 bits each]
/// ```
/// The ECC data is the payload split into ≤223-byte chunks and each chunk
/// RS(255,223)-encoded (adding 32 parity bytes).
public struct StegoEncoder {

    /// 32-bit sync word that marks the start of the bit stream.
    static let syncWord: UInt32 = 0xCAFE_BABE

    /// Maximum supported plaintext payload.
    public static let maxPayloadBytes = 512

    /// Watermark key used to seed the PRNG for coefficient index permutation.
    public let wmKey: [UInt8]

    /// QIM step size.  Larger values improve robustness at the cost of
    /// increased visible distortion.  Default: 32.0.
    public let qimStep: Float

    /// Reed-Solomon codec: RS(255, 223) with 32 parity symbols.
    private let rs = ReedSolomon(nsym: 32)

    public init(wmKey: [UInt8], qimStep: Float = 32.0) {
        self.wmKey = wmKey
        self.qimStep = qimStep
    }

    // MARK: – Public API

    /// Embeds `payload` into a row-major grayscale pixel buffer.
    ///
    /// - Parameters:
    ///   - payload: Up to 512 bytes to hide.
    ///   - pixels:  Row-major `UInt8` luma values, modified in-place.
    ///   - width:   Image width in pixels (must be a multiple of 8).
    ///   - height:  Image height in pixels (must be a multiple of 8).
    public func encode(
        payload: [UInt8],
        into pixels: inout [UInt8],
        width: Int,
        height: Int
    ) throws {
        guard width % 8 == 0 && height % 8 == 0 else {
            throw StegoError.invalidImageDimensions
        }
        guard payload.count <= StegoEncoder.maxPayloadBytes else {
            throw StegoError.payloadTooLarge(size: payload.count,
                                             maxSize: StegoEncoder.maxPayloadBytes)
        }

        // 1. RS-encode the payload in ≤223-byte chunks.
        var eccData = [UInt8]()
        var offset = 0
        while offset < payload.count {
            let end = min(offset + 223, payload.count)
            let chunk = Array(payload[offset..<end])
            eccData += rs.encode(chunk)
            offset = end
        }

        // 2. Build the complete bit stream.
        var bits = [Int]()
        bits.reserveCapacity(64 + eccData.count * 8)
        appendUInt32Bits(StegoEncoder.syncWord, to: &bits)
        appendUInt32Bits(UInt32(eccData.count), to: &bits)
        for byte in eccData { appendByte(byte, to: &bits) }

        // 3. Check capacity.
        let blocksX = width / 8
        let blocksY = height / 8
        let totalBlocks = blocksX * blocksY
        let posPerBlock = DCT8x8Provider.midBandPositions.count
        let totalPositions = totalBlocks * posPerBlock
        guard bits.count <= totalPositions else {
            throw StegoError.insufficientCapacity(needed: bits.count,
                                                  available: totalPositions)
        }

        // 4. Scatter bit→position mapping via PRNG permutation.
        var prng = MeowPRNG(key: wmKey)
        let permutation = prng.shuffled(totalPositions)

        // 5. Embed each bit into the corresponding mid-band DCT coefficient.
        for bitIdx in 0..<bits.count {
            let globalPos = permutation[bitIdx]
            let blockIndex = globalPos / posPerBlock
            let midIdx    = globalPos % posPerBlock

            let blockRow = blockIndex / blocksX
            let blockCol = blockIndex % blocksX
            guard blockRow < blocksY else { continue }

            let (cr, cc) = DCT8x8Provider.midBandPositions[midIdx]
            let coefIdx  = cr * 8 + cc

            // Extract block, DCT, embed, IDCT, write back.
            var block = extractBlock(from: pixels, width: width,
                                     blockRow: blockRow, blockCol: blockCol)
            var coeffs = DCT8x8Provider.dct(block)
            coeffs[coefIdx] = qimEmbed(coeffs[coefIdx], bit: bits[bitIdx],
                                       step: qimStep)
            block = DCT8x8Provider.idct(coeffs)
            writeBlock(block, into: &pixels, width: width,
                       blockRow: blockRow, blockCol: blockCol)
        }
    }

    // MARK: – Helpers

    private func extractBlock(
        from pixels: [UInt8], width: Int, blockRow: Int, blockCol: Int
    ) -> [Float] {
        var block = [Float](repeating: 0, count: 64)
        for r in 0..<8 {
            for c in 0..<8 {
                let idx = (blockRow * 8 + r) * width + (blockCol * 8 + c)
                block[r * 8 + c] = Float(pixels[idx]) - 128.0
            }
        }
        return block
    }

    private func writeBlock(
        _ block: [Float], into pixels: inout [UInt8],
        width: Int, blockRow: Int, blockCol: Int
    ) {
        for r in 0..<8 {
            for c in 0..<8 {
                let idx = (blockRow * 8 + r) * width + (blockCol * 8 + c)
                let v   = block[r * 8 + c] + 128.0
                pixels[idx] = UInt8(max(0, min(255, Int(v.rounded()))))
            }
        }
    }

    private func appendUInt32Bits(_ v: UInt32, to bits: inout [Int]) {
        for shift in stride(from: 31, through: 0, by: -1) {
            bits.append(Int((v >> shift) & 1))
        }
    }

    private func appendByte(_ byte: UInt8, to bits: inout [Int]) {
        for shift in stride(from: 7, through: 0, by: -1) {
            bits.append(Int((byte >> shift) & 1))
        }
    }
}
