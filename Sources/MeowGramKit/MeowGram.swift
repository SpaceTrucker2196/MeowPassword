// Sources/MeowGramKit/MeowGram.swift

#if os(macOS)
import Foundation
import CryptoKit
import MeowStego

/// High-level MeowGram operations: embed / read a provenance GUID (the `.key`
/// band) and embed / read a user message (the disjoint `.message` band), all on
/// the luma channel of a color image so the cat stays in color.
public enum MeowGram {

    /// Conservative UTF-8 byte budget surfaced to the UI. The real hard cap is
    /// `StegoEncoder.maxPayloadBytes` (512); this leaves room for the 1-byte
    /// mode flag and ChaChaPoly's 28-byte overhead when a passphrase is used.
    public static let maxMessageBytes = 400

    public struct DecodedMeowGram {
        public let message: String
        public let guid: String?
        public init(message: String, guid: String?) {
            self.message = message; self.guid = guid
        }
    }

    public enum MGError: Error, CustomStringConvertible {
        case notAMeowGram
        case noMessage
        case wrongPassphrase
        case messageTooLong(Int)
        case malformed
        public var description: String {
            switch self {
            case .notAMeowGram:      return "This image isn't a MeowGram (no provenance key found)."
            case .noMessage:         return "No hidden message found in this MeowGram."
            case .wrongPassphrase:   return "Wrong passphrase — the message couldn't be unlocked."
            case .messageTooLong(let n): return "Message too long (\(n) bytes; max \(maxMessageBytes))."
            case .malformed:         return "The embedded data is malformed."
            }
        }
    }

    // MARK: - GUID <-> bytes

    public static func guidBytes(from uuid: UUID) -> [UInt8] {
        let u = uuid.uuid
        return [u.0, u.1, u.2, u.3, u.4, u.5, u.6, u.7,
                u.8, u.9, u.10, u.11, u.12, u.13, u.14, u.15]
    }

    public static func uuidString(from bytes: [UInt8]) -> String? {
        guard bytes.count == 16 else { return nil }
        let u = (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                 bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15])
        return UUID(uuid: u).uuidString
    }

    // MARK: - Low-level luma operations

    /// Embed a 16-byte GUID into the `.key` band of a luma plane, in place.
    public static func embedGUID(
        _ guid: [UInt8], intoY y: inout [UInt8], width: Int, height: Int
    ) throws {
        let encoder = StegoEncoder(wmKey: MeowGramKeys.keyBandKey,
                                   qimStep: MeowGramKeys.keyBandQimStep,
                                   band: .key)
        try encoder.encode(payload: guid, into: &y, width: width, height: height)
    }

    /// Read a GUID from the `.key` band of a luma plane. Returns `nil` if none.
    public static func readGUID(fromY y: [UInt8], width: Int, height: Int) -> [UInt8]? {
        let decoder = StegoDecoder(wmKey: MeowGramKeys.keyBandKey,
                                   qimStep: MeowGramKeys.keyBandQimStep,
                                   band: .key)
        guard let payload = try? decoder.decode(from: y, width: width, height: height),
              payload.count == 16 else { return nil }
        return payload
    }

    // MARK: - High-level color operations

    /// Embed a message (optionally encrypted with `passphrase`) into a keyed
    /// image. The image must already carry a provenance GUID, which seeds the
    /// message-band scatter key. Returns a new color image; only its luma
    /// changed.
    public static func embedMessage(
        _ message: String, passphrase: String?, into image: ColorImageIO.RGBImage
    ) throws -> ColorImageIO.RGBImage {
        var (y, cb, cr) = YCbCr.fromRGB(rgb: image.rgb, pixelCount: image.pixelCount)
        guard let guid = readGUID(fromY: y, width: image.width, height: image.height) else {
            throw MGError.notAMeowGram
        }

        let payload = try buildPayload(message: message, passphrase: passphrase, guid: guid)
        guard payload.count <= StegoEncoder.maxPayloadBytes else {
            throw MGError.messageTooLong(message.utf8.count)
        }

        let encoder = StegoEncoder(wmKey: messageBandKey(for: guid),
                                   qimStep: MeowGramKeys.messageBandQimStep,
                                   band: .message)
        try encoder.encode(payload: payload, into: &y, width: image.width, height: image.height)

        let rgb = YCbCr.toRGB(y: y, cb: cb, cr: cr)
        return ColorImageIO.RGBImage(rgb: rgb, width: image.width, height: image.height)
    }

    /// Read just the provenance GUID (authenticity) without decoding a message.
    /// Returns `nil` if the image is not an authentic MeowGram.
    public static func readGUIDString(from image: ColorImageIO.RGBImage) -> String? {
        let (y, _, _) = YCbCr.fromRGB(rgb: image.rgb, pixelCount: image.pixelCount)
        guard let guid = readGUID(fromY: y, width: image.width, height: image.height) else {
            return nil
        }
        return uuidString(from: guid)
    }

    /// Read the provenance GUID and (if present) the hidden message from an image.
    public static func readMessage(
        from image: ColorImageIO.RGBImage, passphrase: String?
    ) throws -> DecodedMeowGram {
        let (y, _, _) = YCbCr.fromRGB(rgb: image.rgb, pixelCount: image.pixelCount)
        guard let guid = readGUID(fromY: y, width: image.width, height: image.height) else {
            throw MGError.notAMeowGram
        }
        let guidString = uuidString(from: guid)

        let decoder = StegoDecoder(wmKey: messageBandKey(for: guid),
                                   qimStep: MeowGramKeys.messageBandQimStep,
                                   band: .message)
        guard let payload = try? decoder.decode(from: y, width: image.width, height: image.height) else {
            throw MGError.noMessage
        }
        let message = try parsePayload(payload, passphrase: passphrase, guid: guid)
        return DecodedMeowGram(message: message, guid: guidString)
    }

    // MARK: - File-path convenience (CLI)

    public static func embedMessage(
        inPath: String, outPath: String, message: String, passphrase: String?
    ) throws {
        let image = try ColorImageIO.readRGBImage(path: inPath)
        let out = try embedMessage(message, passphrase: passphrase, into: image)
        try ColorImageIO.writePNG(out, to: outPath)
    }

    public static func readMessage(inPath: String, passphrase: String?) throws -> DecodedMeowGram {
        let image = try ColorImageIO.readRGBImage(path: inPath)
        return try readMessage(from: image, passphrase: passphrase)
    }

    // MARK: - Payload framing

    // Payload layout: [1-byte mode flag][body]
    //   flag 0x00 → body is raw UTF-8
    //   flag 0x01 → body is a ChaChaPoly combined box (nonce|ciphertext|tag)
    private static let flagPlain: UInt8 = 0x00
    private static let flagEncrypted: UInt8 = 0x01

    private static func buildPayload(message: String, passphrase: String?, guid: [UInt8]) throws -> [UInt8] {
        let plaintext = Data(message.utf8)
        guard message.utf8.count <= maxMessageBytes else {
            throw MGError.messageTooLong(message.utf8.count)
        }
        if let pass = passphrase, !pass.isEmpty {
            let key = encryptionKey(passphrase: pass, guid: guid)
            let sealed = try ChaChaPoly.seal(plaintext, using: key)
            return [flagEncrypted] + [UInt8](sealed.combined)
        } else {
            return [flagPlain] + [UInt8](plaintext)
        }
    }

    private static func parsePayload(_ payload: [UInt8], passphrase: String?, guid: [UInt8]) throws -> String {
        guard let flag = payload.first else { throw MGError.malformed }
        let body = Array(payload.dropFirst())
        switch flag {
        case flagPlain:
            guard let s = String(bytes: body, encoding: .utf8) else { throw MGError.malformed }
            return s
        case flagEncrypted:
            guard let pass = passphrase, !pass.isEmpty else { throw MGError.wrongPassphrase }
            let key = encryptionKey(passphrase: pass, guid: guid)
            guard let box = try? ChaChaPoly.SealedBox(combined: Data(body)),
                  let opened = try? ChaChaPoly.open(box, using: key),
                  let s = String(data: opened, encoding: .utf8) else {
                throw MGError.wrongPassphrase
            }
            return s
        default:
            throw MGError.malformed
        }
    }

    // MARK: - Key derivation

    /// Per-image message-band scatter key: SHA256(label || guid). Not secret —
    /// covertness only; confidentiality is the passphrase's job.
    private static func messageBandKey(for guid: [UInt8]) -> [UInt8] {
        var hasher = SHA256()
        hasher.update(data: Data(MeowGramKeys.messageKeyLabel.utf8))
        hasher.update(data: Data(guid))
        return Array(hasher.finalize())
    }

    /// ChaChaPoly key from a passphrase, salted by the image's GUID.
    private static func encryptionKey(passphrase: String, guid: [UInt8]) -> SymmetricKey {
        let ikm = SymmetricKey(data: Data(passphrase.utf8))
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: ikm,
            salt: Data(guid),
            info: Data("meowgram-enc-v1".utf8),
            outputByteCount: 32
        )
    }
}
#endif
