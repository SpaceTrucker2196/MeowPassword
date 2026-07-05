// Sources/MeowStego/StegoDecoder.swift

/// Decodes a steganographic payload from the luma channel of a grayscale image.
///
/// The decoder reverses the pipeline applied by `StegoEncoder`:
/// 1. Re-generate the same PRNG permutation from the shared `wmKey`.
/// 2. For each position, apply DCT and use QIM extraction to read a bit.
/// 3. Locate the 32-bit sync preamble.
/// 4. Read the ECC data length and the encoded bytes.
/// 5. RS-decode each chunk and concatenate to recover the original payload.
public struct StegoDecoder {

    /// Watermark key (must match the encoder's key).
    public let wmKey: [UInt8]

    /// QIM step size (must match the encoder's step).
    public let qimStep: Float

    /// The mid-band coefficient slice to read from (must match the encoder's
    /// band). Default `.full` preserves historical behavior.
    public let band: StegoBand

    private let rs = ReedSolomon(nsym: 32)

    public init(wmKey: [UInt8], qimStep: Float = 32.0, band: StegoBand = .full) {
        self.wmKey = wmKey
        self.qimStep = qimStep
        self.band = band
    }

    // MARK: – Public API

    /// Extracts a previously embedded payload from a row-major grayscale pixel buffer.
    ///
    /// - Parameters:
    ///   - pixels: Row-major `UInt8` luma values.
    ///   - width:  Image width in pixels (must be a multiple of 8).
    ///   - height: Image height in pixels (must be a multiple of 8).
    /// - Returns: The recovered plaintext payload bytes.
    /// - Throws:  `StegoError` if the sync word is missing or ECC fails.
    public func decode(from pixels: [UInt8], width: Int, height: Int) throws -> [UInt8] {
        guard width % 8 == 0 && height % 8 == 0 else {
            throw StegoError.invalidImageDimensions
        }

        let blocksX = width / 8
        let blocksY = height / 8
        let totalBlocks = blocksX * blocksY
        let bandPositions = band.positions
        let posPerBlock = bandPositions.count
        let totalPositions = totalBlocks * posPerBlock

        // 1. Reconstruct the same permutation the encoder used.
        var prng = MeowPRNG(key: wmKey)
        let permutation = prng.shuffled(totalPositions)

        // 2. Extract all available bits in permuted order.
        var extractedBits = [Int]()
        extractedBits.reserveCapacity(totalPositions)

        for globalPos in permutation {
            let blockIndex = globalPos / posPerBlock
            let midIdx     = globalPos % posPerBlock

            let blockRow = blockIndex / blocksX
            let blockCol = blockIndex % blocksX
            guard blockRow < blocksY else {
                extractedBits.append(0)
                continue
            }

            let (cr, cc) = bandPositions[midIdx]
            let coefIdx  = cr * 8 + cc

            let block  = extractBlock(from: pixels, width: width,
                                      blockRow: blockRow, blockCol: blockCol)
            let coeffs = DCT8x8Provider.dct(block)
            extractedBits.append(qimExtract(coeffs[coefIdx], step: qimStep))
        }

        // 3. Find the sync word.
        let syncBits = uint32ToBits(StegoEncoder.syncWord)
        guard let syncStart = findSync(in: extractedBits, pattern: syncBits) else {
            throw StegoError.syncNotFound
        }

        // 4. Read the ECC data length (32 bits after the sync word).
        let lenStart = syncStart + 32
        guard lenStart + 32 <= extractedBits.count else {
            throw StegoError.malformedStream
        }
        let eccLen = Int(bitsToUInt32(Array(extractedBits[lenStart..<lenStart + 32])))
        guard eccLen > 0 && eccLen <= 10_000 else {
            throw StegoError.malformedStream
        }

        // 5. Read the ECC data bytes.
        let dataStart = lenStart + 32
        guard dataStart + eccLen * 8 <= extractedBits.count else {
            throw StegoError.malformedStream
        }
        var eccData = [UInt8](repeating: 0, count: eccLen)
        for i in 0..<eccLen {
            var byte: UInt8 = 0
            for b in 0..<8 {
                byte = (byte << 1) | UInt8(extractedBits[dataStart + i * 8 + b])
            }
            eccData[i] = byte
        }

        // 6. RS-decode each 255-byte codeword chunk.
        var payload = [UInt8]()
        var offset = 0
        while offset < eccData.count {
            let chunkSize = min(255, eccData.count - offset)
            let chunk = Array(eccData[offset..<offset + chunkSize])
            guard let decoded = rs.decode(chunk) else {
                throw StegoError.eccDecodingFailed
            }
            payload += decoded
            offset += chunkSize
        }

        return payload
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

    private func uint32ToBits(_ v: UInt32) -> [Int] {
        return (0..<32).map { Int((v >> (31 - $0)) & 1) }
    }

    private func bitsToUInt32(_ bits: [Int]) -> UInt32 {
        var v: UInt32 = 0
        for b in bits { v = (v << 1) | UInt32(b) }
        return v
    }

    /// Finds the first occurrence of `pattern` in `stream`, returning its start index.
    private func findSync(in stream: [Int], pattern: [Int]) -> Int? {
        guard stream.count >= pattern.count else { return nil }
        outer: for i in 0...(stream.count - pattern.count) {
            for j in 0..<pattern.count {
                if stream[i + j] != pattern[j] { continue outer }
            }
            return i
        }
        return nil
    }
}
