//
//  main.swift
//  MeowPassword
//
//  Created by Jeffrey Kunzelman on 8/23/25.
//

import Foundation
import MeowStego
import MeowPassCore
#if os(macOS)
import MeowGramKit
import Security
import CoreGraphics
import ImageIO
import CryptoKit
#endif

/// Build a MeowPassCore generation config from the CLI's parsed arguments.
private func coreConfig(_ c: PasswordConfig) -> MeowPassCore.PasswordConfig {
    MeowPassCore.PasswordConfig(numNumbers: c.numNumbers, numSymbols: c.numSymbols, maxLength: c.maxLength)
}

// MARK: - ASCII Art and Lolcat Theme
let lolcatArt = """
                         _,-;'''`' - .
                      _/',  `;  `;    \\
      ,        _..,-''    '   `  `      `\\
     | ;._.,,-' .| |,_     '   '         `\\
     | `;'      ;' ;, `,   ; |    '  '  .   \\
     `; __`  ,'__  ` ,  ` ;  |      ;        \\
     ; (6_);  (6_) ; |   ,    \\        '      |       
    ;;   _,6 ,.    ` `,   '    `-._           //   
     ,;.=..`_..=.,' -'          ,''        _,//
_00_____`"=,,,=="',___,,,-----'''----'_'_'_''______00_
	Meow Password Generators of Secure Relavant
                               __,,-' /'       
                             /'_,,--''
                            | (
                             `'
"""
// MARK: - Version / Update Metadata

let meowpassVersion = "1.1.0"
let meowpassGithubOwner = "SpaceTrucker2196"
let meowpassGithubRepo = "MeowPassword"

// MARK: - Configuration Structure

/**
 * Configuration structure for password generation parameters
 * Handles command-line argument parsing and parameter validation
 */
struct PasswordConfig {
    let numNumbers: Int     // Number of random numbers to insert (1-10)
    let numSymbols: Int     // Number of random symbols to insert (1-10)
    let maxLength: Int      // Maximum password length (15-50)
    let showTests: Bool     // Whether to run test mode
    let copyToClipboard: Bool // Whether to copy result to clipboard
    let saveToKeychain: Bool  // Whether to save to Apple Keychain
    let keychainService: String // Keychain service name
    let keychainAccount: String // Keychain account name
    let psssst: Bool        // Silent mode — copy winner, print nothing
    let showHelp: Bool      // Whether the user asked for help
    let checkUpdate: Bool   // Whether to check GitHub for updates
    let analyzeString: String? // If set, score this string instead of generating


    /**
     * Initialize configuration from command line arguments
     * @param arguments: Array of command line arguments
     */
    init(arguments: [String]) {
        var numNumbers = Int.random(in: 1...4)  // Default range as specified in requirements
        var numSymbols = 2  // Default value as specified in requirements
        var maxLength = 25  // Default max length as specified in requirements
        var showTests = false
        var copyToClipboard = false
        var saveToKeychain = false
        var keychainService = "MeowPassword"
        var keychainAccount = "generated"
        var psssst = false
        var showHelp = false
        var checkUpdate = false
        var analyzeString: String? = nil


        // Parse command line arguments with validation
        var i = 0
        while i < arguments.count {
            switch arguments[i] {
            case "--numbers":
                if i + 1 < arguments.count, let value = Int(arguments[i + 1]) {
                    numNumbers = max(1, min(10, value))  // Clamp between 1-10
                    i += 1
                }
            case "--symbols":
                if i + 1 < arguments.count, let value = Int(arguments[i + 1]) {
                    numSymbols = max(1, min(10, value))  // Clamp between 1-10
                    i += 1
                }
            case "--max-length":
                if i + 1 < arguments.count, let value = Int(arguments[i + 1]) {
                    maxLength = max(15, min(50, value))  // Clamp between 15-50
                    i += 1
                }
            case "--test":
                showTests = true
            case "--copy":
                copyToClipboard = true
            case "--save-to-keychain":
                saveToKeychain = true
            case "--service":
                if i + 1 < arguments.count { keychainService = arguments[i + 1]; i += 1 }
            case "--account":
                if i + 1 < arguments.count { keychainAccount = arguments[i + 1]; i += 1 }
            case "--psssst", "-p":
                psssst = true
                copyToClipboard = true
            case "--help", "-h":
                showHelp = true
            case "--update":
                checkUpdate = true
            case "--analyze", "-a":
                if i + 1 < arguments.count {
                    analyzeString = arguments[i + 1]
                    i += 1
                }
            default:
                break
            }
            i += 1
        }

        self.numNumbers = numNumbers
        self.numSymbols = numSymbols
        self.maxLength = maxLength
        self.showTests = showTests
        self.copyToClipboard = copyToClipboard
        self.saveToKeychain = saveToKeychain
        self.keychainService = keychainService
        self.keychainAccount = keychainAccount
        self.psssst = psssst
        self.showHelp = showHelp
        self.checkUpdate = checkUpdate
        self.analyzeString = analyzeString
    }
}

// MARK: - Test Functions

/**
 * Helper function to assert test conditions and print results
 * @param condition: Boolean condition to test
 * @param message: Description of what is being tested
 */
func assert(_ condition: Bool, _ message: String) {
    if condition {
        print("PASS: \(message)")
    } else {
        print("FAIL: \(message)")
    }
}

/**
 * Helper function to assert equality and print results
 * @param actual: The actual value received
 * @param expected: The expected value
 * @param message: Description of what is being tested
 */
func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String) {
    if actual == expected {
        print("PASS: \(message)")
    } else {
        print("FAIL: \(message) - Expected: \(expected), Got: \(actual)")
    }
}

/**
 * Test the cat name loading functionality
 * Verifies that embedded cat names are properly loaded and accessible
 */
func testLoadCatNames() {
    print("\nTesting Cat Name Loading...")

    let catNames = MeowPass.catNames()
    assert(!catNames.isEmpty, "Should Meow load cat names from embedded data")
    assert(catNames.count > 100, "Should load a substantial Meow number of cat names")

    let nonEmptyNames = catNames.filter { !$0.isEmpty }
    assertEqual(nonEmptyNames.count, catNames.count, "All Meow Meow loaded names should be non-empty")

    print("Cat names loaded meow: \(catNames.count)")
    print("First few names: \(Array(catNames.prefix(5)))")
}

/**
 * Test the complete password generation process
 * Validates that passwords meet all security requirements
 */
func testCompletePasswordGeneration() {
    print("\nTesting MeowMeow Complete Password Generation...")

    let config = PasswordConfig(arguments: [])

    for (i, candidate) in MeowPass.generate(config: coreConfig(config), count: 3).enumerated() {
        let password = candidate.password

        print("Generated password \(i + 1): \(password)")

        assert(password.count >= 10, "MeowPassword should be at least 10 characters")
        assert(password.count <= config.maxLength + 10, "Password should not greatly exceed Meow max length")

        let hasNumbers = password.contains { $0.isNumber }
        let hasLetters = password.contains { $0.isLetter }
        let hasSymbols = password.contains { !$0.isLetter && !$0.isNumber }

        assert(hasNumbers, "Password should contain meow numbers")
        assert(hasLetters, "Password meow should contain letters")
        assert(hasSymbols, "Password should contain meow symbols")

        let (score, analysis) = (candidate.score, candidate.analysis)
        assert(score >= 0.0 && score <= 10.0, "Complexity score should be meow valid")
        assert(!analysis.isEmpty, "Analysis should not be meow empty")
    }
}

/**
 * Run all basic tests for the MeowPassword system
 * Executes comprehensive testing of all core functionality
 */
func runBasicTests() {
    print("Running Basic MeowPassword Tests")
    print("=================================")
    
    testLoadCatNames()
    testCompletePasswordGeneration()
    
    print("\nMeow Basic Tests Complete!")
    print("=====================")
}

// MARK: - Help Function

// MARK: - Apple Keychain Integration

#if os(macOS)
/**
 * Save a password to the macOS Keychain (iCloud Keychain if configured).
 * Uses Apple's Security framework to store passwords securely via the
 * kSecClassGenericPassword item class.
 * @param password: The password string to save
 * @param service: The service name for the keychain entry (e.g., "com.example.myapp")
 * @param account: The account name associated with the password (e.g., username or email)
 * @return True if the password was saved or updated successfully, false otherwise
 */
func savePasswordToKeychain(password: String, service: String, account: String) -> Bool {
    guard let passwordData = password.data(using: .utf8) else { return false }

    // Build the keychain query dictionary for a generic password item
    let query: [String: Any] = [
        kSecClass as String:       kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account
    ]

    // If an entry already exists for this service/account, update its value
    if SecItemCopyMatching(query as CFDictionary, nil) == errSecSuccess {
        let updateAttrs: [String: Any] = [kSecValueData as String: passwordData]
        return SecItemUpdate(query as CFDictionary, updateAttrs as CFDictionary) == errSecSuccess
    }

    // Otherwise add a new item
    var addQuery = query
    addQuery[kSecValueData as String] = passwordData
    return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
}
#endif



/// Read a PGM (P5 binary) file.  Returns (pixels, width, height) or nil on error.
func readPGM(path: String) -> (pixels: [UInt8], width: Int, height: Int)? {
    guard let data = FileManager.default.contents(atPath: path) else { return nil }
    let bytes = [UInt8](data)

    // Parse ASCII header tokens separated by whitespace/newlines, skipping # comments.
    var idx = 0
    var tokens: [String] = []
    while tokens.count < 4 && idx < bytes.count {
        // Skip whitespace and comments.
        while idx < bytes.count && (bytes[idx] == 32 || bytes[idx] == 10 ||
              bytes[idx] == 13 || bytes[idx] == 9) { idx += 1 }
        if idx < bytes.count && bytes[idx] == UInt8(ascii: "#") {
            while idx < bytes.count && bytes[idx] != 10 { idx += 1 }
            continue
        }
        var tok = ""
        while idx < bytes.count && bytes[idx] != 32 && bytes[idx] != 10 &&
              bytes[idx] != 13 && bytes[idx] != 9 {
            tok.append(Character(UnicodeScalar(bytes[idx])))
            idx += 1
        }
        if !tok.isEmpty { tokens.append(tok) }
    }

    guard tokens.count == 4,
          tokens[0] == "P5",
          let w = Int(tokens[1]), let h = Int(tokens[2]),
          let maxVal = Int(tokens[3]), maxVal == 255 else { return nil }

    // Skip the single whitespace byte that separates header from pixel data.
    if idx < bytes.count { idx += 1 }

    guard idx + w * h <= bytes.count else { return nil }
    return (Array(bytes[idx..<idx + w * h]), w, h)
}

/// Write a PGM (P5 binary) file.  Returns false on error.
@discardableResult
func writePGM(pixels: [UInt8], width: Int, height: Int, path: String) -> Bool {
    let header = "P5\n\(width) \(height)\n255\n"
    var data = Data(header.utf8)
    data.append(contentsOf: pixels)
    return FileManager.default.createFile(atPath: path, contents: data)
}

#if os(macOS)
/// Read a PNG or GIF file and return its first frame as an 8-bit grayscale luma buffer.
/// Returns (pixels, width, height) or nil on error.
func readGrayImage(path: String) -> (pixels: [UInt8], width: Int, height: Int)? {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let source = CGImageSourceCreateWithURL(url, nil),
          let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }
    let width  = cgImage.width
    let height = cgImage.height
    let colorSpace = CGColorSpaceCreateDeviceGray()
    var pixels = [UInt8](repeating: 0, count: width * height)
    guard let ctx = CGContext(
        data: &pixels,
        width: width, height: height,
        bitsPerComponent: 8, bytesPerRow: width,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.none.rawValue
    ) else { return nil }
    // CoreGraphics uses bottom-left origin; flip so row 0 is the top of the image.
    ctx.translateBy(x: 0, y: CGFloat(height))
    ctx.scaleBy(x: 1.0, y: -1.0)
    ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
    return (pixels, width, height)
}

/// Write an 8-bit grayscale luma buffer to a PNG file.
@discardableResult
func writePNG(pixels: [UInt8], width: Int, height: Int, path: String) -> Bool {
    let colorSpace = CGColorSpaceCreateDeviceGray()
    guard let provider = CGDataProvider(data: Data(pixels) as CFData),
          let cgImage = CGImage(
              width: width, height: height,
              bitsPerComponent: 8, bitsPerPixel: 8,
              bytesPerRow: width, space: colorSpace,
              bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
              provider: provider, decode: nil, shouldInterpolate: false,
              intent: .defaultIntent
          ) else { return false }
    let url = URL(fileURLWithPath: path) as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil)
    else { return false }
    CGImageDestinationAddImage(dest, cgImage, nil)
    return CGImageDestinationFinalize(dest)
}

/// Write an 8-bit grayscale luma buffer to a GIF file.
/// Note: GIF is limited to a 256-color palette; a full grayscale palette is used.
@discardableResult
func writeGIF(pixels: [UInt8], width: Int, height: Int, path: String) -> Bool {
    let colorSpace = CGColorSpaceCreateDeviceGray()
    guard let provider = CGDataProvider(data: Data(pixels) as CFData),
          let cgImage = CGImage(
              width: width, height: height,
              bitsPerComponent: 8, bitsPerPixel: 8,
              bytesPerRow: width, space: colorSpace,
              bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
              provider: provider, decode: nil, shouldInterpolate: false,
              intent: .defaultIntent
          ) else { return false }
    let url = URL(fileURLWithPath: path) as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, "com.compuserve.gif" as CFString, 1, nil)
    else { return false }
    CGImageDestinationAddImage(dest, cgImage, nil)
    return CGImageDestinationFinalize(dest)
}
#endif

/// Read any supported image (PGM, PNG, GIF, JPEG) as an 8-bit grayscale
/// luma buffer. The format is detected from the file-path extension.
///
/// Note: JPEG input is decoded through ImageIO like any other raster. That
/// works fine as a *source* for embedding (the raster is what we run DCT
/// on). Extracting a payload from a JPEG only succeeds if that JPEG has
/// never been JPEG-re-encoded since the stego was written — see
/// `writeImage` for the reasoning.
func readImage(path: String) -> (pixels: [UInt8], width: Int, height: Int)? {
    switch URL(fileURLWithPath: path).pathExtension.lowercased() {
    case "png", "gif", "jpg", "jpeg":
        #if os(macOS)
        return readGrayImage(path: path)
        #else
        print("ERROR: PNG/GIF/JPEG support is only available on macOS")
        return nil
        #endif
    default:          // "pgm" and unknown extensions fall through to PGM parser
        if URL(fileURLWithPath: path).pathExtension.lowercased() != "pgm" {
            print("WARNING: Unknown extension '\(URL(fileURLWithPath: path).pathExtension)', attempting PGM format")
        }
        return readPGM(path: path)
    }
}

/// Write an 8-bit grayscale luma buffer to a file.
/// Supported output formats: PGM, PNG, GIF. JPEG output is refused —
/// see below.
@discardableResult
func writeImage(pixels: [UInt8], width: Int, height: Int, path: String) -> Bool {
    switch URL(fileURLWithPath: path).pathExtension.lowercased() {
    case "png":
        #if os(macOS)
        return writePNG(pixels: pixels, width: width, height: height, path: path)
        #else
        print("ERROR: PNG support is only available on macOS")
        return false
        #endif
    case "gif":
        #if os(macOS)
        return writeGIF(pixels: pixels, width: width, height: height, path: path)
        #else
        print("ERROR: GIF support is only available on macOS")
        return false
        #endif
    case "jpg", "jpeg":
        // JPEG can't be a stego *output*. The embedder writes a payload
        // into DCT coefficients; re-encoding those coefficients through
        // JPEG's own quantization and Huffman coding shifts the values
        // and destroys the payload. Save to PNG or GIF (both lossless)
        // and JPEG-convert later if needed for size, accepting that the
        // payload won't survive that step.
        print("ERROR: JPEG is not supported as a stego output — its lossy re-encoding")
        print("       would destroy the embedded DCT payload. Write to .png or .gif")
        print("       instead.")
        return false
    default:          // "pgm" and unknown extensions fall through to PGM writer
        if URL(fileURLWithPath: path).pathExtension.lowercased() != "pgm" {
            print("WARNING: Unknown extension '\(URL(fileURLWithPath: path).pathExtension)', writing as PGM format")
        }
        return writePGM(pixels: pixels, width: width, height: height, path: path)
    }
}

/// Convert an RGB PPM buffer to an 8-bit luma (Y) channel using BT.601.
func rgbToLuma(rgb: [UInt8], width: Int, height: Int) -> [UInt8] {
    var luma = [UInt8](repeating: 0, count: width * height)
    for i in 0..<width * height {
        let r = Float(rgb[i * 3 + 0])
        let g = Float(rgb[i * 3 + 1])
        let b = Float(rgb[i * 3 + 2])
        luma[i] = UInt8(min(255, max(0, Int(0.299 * r + 0.587 * g + 0.114 * b))))
    }
    return luma
}

/// Resolve a watermark-key argument: supports `hex:AABBCC...` or a raw ASCII passphrase.
func resolveWmKey(_ arg: String) -> [UInt8]? {
    if arg.lowercased().hasPrefix("hex:") {
        let hex = String(arg.dropFirst(4))
        return MeowPRNG(hexKey: hex).map { _ in
            var idx = hex.startIndex
            var bytes = [UInt8]()
            while idx < hex.endIndex {
                let next = hex.index(idx, offsetBy: 2)
                if let b = UInt8(hex[idx..<next], radix: 16) { bytes.append(b) }
                idx = next
            }
            return bytes
        }
    }
    return Array(arg.utf8)
}

/// `meowpass steg-embed` subcommand handler.
func runStegoEmbed(args: [String]) {
    var inPath: String?
    var outPath: String?
    var payloadPath: String?
    var wmKeyArg: String?
    var qimStep: Float = 32.0

    var i = 0
    while i < args.count {
        switch args[i] {
        case "--in":        i += 1; if i < args.count { inPath = args[i] }
        case "--out":       i += 1; if i < args.count { outPath = args[i] }
        case "--payload-file": i += 1; if i < args.count { payloadPath = args[i] }
        case "--wm-key":    i += 1; if i < args.count { wmKeyArg = args[i] }
        case "--qim-step":  i += 1; if i < args.count, let f = Float(args[i]) { qimStep = f }
        default: break
        }
        i += 1
    }

    guard let ip = inPath, let op = outPath, let pp = payloadPath, let wkArg = wmKeyArg else {
        print("Usage: meowpass steg-embed --in <image.pgm|png|gif|jpg|jpeg> --out <stego.pgm|png|gif>")
        print("                           --payload-file <file> --wm-key hex:<hex>|<passphrase>")
        print("       (JPEG is accepted as input but not as output — its re-quantization")
        print("        would destroy the embedded payload.)")
        return
    }

    guard let wmKey = resolveWmKey(wkArg) else {
        print("ERROR: Invalid --wm-key format"); return
    }
    guard let pgmResult = readImage(path: ip) else {
        print("ERROR: Cannot read image file '\(ip)'"); return
    }
    var pixels = pgmResult.pixels
    let width  = pgmResult.width
    let height = pgmResult.height
    guard let payloadData = FileManager.default.contents(atPath: pp) else {
        print("ERROR: Cannot read payload file '\(pp)'"); return
    }

    let payload = [UInt8](payloadData)
    let encoder = StegoEncoder(wmKey: wmKey, qimStep: qimStep)
    do {
        try encoder.encode(payload: payload, into: &pixels, width: width, height: height)
        if writeImage(pixels: pixels, width: width, height: height, path: op) {
            print("✅ Payload embedded → '\(op)'  (\(payload.count) bytes in \(width)×\(height) image)")
        } else {
            print("ERROR: Cannot write output file '\(op)'")
        }
    } catch {
        print("ERROR: \(error)")
    }
}

/// `meowpass steg-extract` subcommand handler.
func runStegoExtract(args: [String]) {
    var inPath: String?
    var wmKeyArg: String?
    var rawOutput = false
    var qimStep: Float = 32.0

    var i = 0
    while i < args.count {
        switch args[i] {
        case "--in":       i += 1; if i < args.count { inPath = args[i] }
        case "--wm-key":   i += 1; if i < args.count { wmKeyArg = args[i] }
        case "--raw":      rawOutput = true
        case "--qim-step": i += 1; if i < args.count, let f = Float(args[i]) { qimStep = f }
        default: break
        }
        i += 1
    }

    guard let ip = inPath, let wkArg = wmKeyArg else {
        print("Usage: meowpass steg-extract --in <image.pgm|png|gif|jpg|jpeg> --wm-key hex:<hex>|<passphrase>")
        print("                             [--raw]")
        return
    }

    guard let wmKey = resolveWmKey(wkArg) else {
        print("ERROR: Invalid --wm-key format"); return
    }
    guard let (pixels, width, height) = readImage(path: ip) else {
        print("ERROR: Cannot read image file '\(ip)'"); return
    }

    let decoder = StegoDecoder(wmKey: wmKey, qimStep: qimStep)
    do {
        let payload = try decoder.decode(from: pixels, width: width, height: height)
        if rawOutput {
            FileHandle.standardOutput.write(Data(payload))
        } else {
            let text = String(bytes: payload, encoding: .utf8)
                    ?? "<binary \(payload.count) bytes>"
            print("✅ Extracted \(payload.count) bytes: \(text)")
        }
    } catch {
        print("ERROR: \(error)")
    }
}

#if os(macOS)
// MARK: - MeowGram subcommands

/// Parse a "WxH" size string into (width, height), both required multiples of 8.
private func parseSize(_ s: String) -> (Int, Int)? {
    let parts = s.lowercased().split(separator: "x")
    guard parts.count == 2, let w = Int(parts[0]), let h = Int(parts[1]),
          w > 0, h > 0, w % 8 == 0, h % 8 == 0 else { return nil }
    return (w, h)
}

private func sha256Hex(ofFile path: String) -> String? {
    guard let data = FileManager.default.contents(atPath: path) else { return nil }
    return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
}

/// `meowpass meowgram-prep` — bake a provenance GUID into each source image and
/// record the mapping in a manifest.
func runMeowgramPrep(args: [String]) {
    var inDir = "meowgrams"
    var outDir = "Sources/MeowPasswordApp/Meowgrams"
    var manifestPath = "meowgrams/manifest.json"
    var sizeArg = "544x680"
    var doVerify = true
    var force = false

    var i = 0
    while i < args.count {
        switch args[i] {
        case "--in-dir":   i += 1; if i < args.count { inDir = args[i] }
        case "--out-dir":  i += 1; if i < args.count { outDir = args[i] }
        case "--manifest": i += 1; if i < args.count { manifestPath = args[i] }
        case "--size":     i += 1; if i < args.count { sizeArg = args[i] }
        case "--verify":    doVerify = true
        case "--no-verify": doVerify = false
        case "--force":     force = true
        default: break
        }
        i += 1
    }

    guard let (targetW, targetH) = parseSize(sizeArg) else {
        print("ERROR: --size must be WxH with both dimensions multiples of 8 (e.g. 544x680)")
        return
    }
    let fm = FileManager.default
    if fm.fileExists(atPath: manifestPath) && !force {
        print("ERROR: \(manifestPath) already exists. Re-running mints new GUIDs and orphans")
        print("       already-shipped images. Pass --force only if you really mean to.")
        return
    }
    guard let entries = try? fm.contentsOfDirectory(atPath: inDir) else {
        print("ERROR: Cannot list --in-dir '\(inDir)'"); return
    }
    let jpgs = entries
        .filter { ["jpg", "jpeg"].contains(($0 as NSString).pathExtension.lowercased()) }
        .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    guard !jpgs.isEmpty else {
        print("ERROR: No .jpg files in '\(inDir)'"); return
    }
    try? fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)

    var manifestImages: [MeowGramManifest.Entry] = []
    let bigMsg = String(repeating: "M", count: MeowGram.maxMessageBytes)

    print("Prepping \(jpgs.count) images → \(targetW)×\(targetH) keyed PNGs in \(outDir)")
    for name in jpgs {
        let srcPath = (inDir as NSString).appendingPathComponent(name)
        let baseName = (name as NSString).deletingPathExtension
        let outName = baseName + ".png"
        let outPath = (outDir as NSString).appendingPathComponent(outName)

        do {
            let src = try ColorImageIO.readRGBImage(path: srcPath)
            let scaled = try ColorImageIO.cropAndScale(src, targetW: targetW, targetH: targetH)

            var (y, cb, cr) = YCbCr.fromRGB(rgb: scaled.rgb, pixelCount: scaled.pixelCount)
            let uuid = UUID()
            let guid = MeowGram.guidBytes(from: uuid)
            try MeowGram.embedGUID(guid, intoY: &y, width: targetW, height: targetH)

            let keyed = ColorImageIO.RGBImage(
                rgb: YCbCr.toRGB(y: y, cb: cb, cr: cr), width: targetW, height: targetH)

            if doVerify {
                // Simulate a worst-case user message embed and confirm both the
                // GUID and the message survive the color + disjoint-band round-trip.
                let stego = try MeowGram.embedMessage(bigMsg, passphrase: nil, into: keyed)
                let decoded = try MeowGram.readMessage(from: stego, passphrase: nil)
                guard decoded.guid == uuid.uuidString, decoded.message == bigMsg else {
                    print("❌ VERIFY FAILED for \(name): provenance key did not survive a message embed.")
                    print("   Aborting prep — do not ship these masters.")
                    return
                }
            }

            try ColorImageIO.writePNG(keyed, to: outPath)
            let hash = sha256Hex(ofFile: outPath) ?? ""
            manifestImages.append(.init(file: outName, source: name,
                                        guid: uuid.uuidString, sha256: hash))
            print("  ✓ \(name) → \(outName)  guid \(uuid.uuidString)")
        } catch {
            print("❌ \(name): \(error)")
            return
        }
    }

    let iso = ISO8601DateFormatter()
    iso.timeZone = TimeZone(identifier: "UTC")
    let manifest = MeowGramManifest(
        version: 1,
        created: iso.string(from: Date()),
        keyBand: .init(zigZag: [10, 14], qimStep: Double(MeowGramKeys.keyBandQimStep)),
        geometry: .init(width: targetW, height: targetH),
        images: manifestImages
    )
    do {
        try manifest.write(path: manifestPath)
        print("✅ Wrote \(manifestImages.count) keyed masters + manifest → \(manifestPath)")
        print("   Remember: git-crypt the manifest before committing (see plan §2b).")
    } catch {
        print("ERROR: Could not write manifest: \(error)")
    }
}

/// `meowpass meowgram-embed` — embed a message into a keyed image.
func runMeowgramEmbed(args: [String]) {
    var inPath: String?, outPath: String?, msgFile: String?, passphrase: String?
    var i = 0
    while i < args.count {
        switch args[i] {
        case "--in":           i += 1; if i < args.count { inPath = args[i] }
        case "--out":          i += 1; if i < args.count { outPath = args[i] }
        case "--message-file": i += 1; if i < args.count { msgFile = args[i] }
        case "--passphrase":   i += 1; if i < args.count { passphrase = args[i] }
        default: break
        }
        i += 1
    }
    guard let ip = inPath, let op = outPath, let mf = msgFile else {
        print("Usage: meowpass meowgram-embed --in <keyed.png> --out <mail.png>")
        print("                               --message-file <file> [--passphrase <p>]")
        return
    }
    guard let msgData = FileManager.default.contents(atPath: mf),
          let message = String(data: msgData, encoding: .utf8) else {
        print("ERROR: Cannot read --message-file '\(mf)' as UTF-8"); return
    }
    do {
        try MeowGram.embedMessage(inPath: ip, outPath: op,
                                  message: message.trimmingCharacters(in: .newlines),
                                  passphrase: passphrase)
        print("✅ MeowGram written → '\(op)' (keep it PNG — lossy re-encoding destroys it)")
    } catch {
        print("ERROR: \(error)")
    }
}

/// `meowpass meowgram-read` — read GUID + message from a MeowGram.
func runMeowgramRead(args: [String]) {
    var inPath: String?, passphrase: String?
    var i = 0
    while i < args.count {
        switch args[i] {
        case "--in":         i += 1; if i < args.count { inPath = args[i] }
        case "--passphrase": i += 1; if i < args.count { passphrase = args[i] }
        default: break
        }
        i += 1
    }
    guard let ip = inPath else {
        print("Usage: meowpass meowgram-read --in <mail.png> [--passphrase <p>]"); return
    }
    do {
        let decoded = try MeowGram.readMessage(inPath: ip, passphrase: passphrase)
        print("GUID: \(decoded.guid ?? "<none>")")
        print("Message: \(decoded.message)")
    } catch {
        print("ERROR: \(error)")
    }
}
#endif

/// `meowpass meow-key` — build a voice-friendly `catname-catname-catname`
/// passphrase from short single-word names in the embedded database.
func runMeowKey(args: [String]) {
    var words = 3
    var maxLen = 5

    var i = 0
    while i < args.count {
        switch args[i] {
        case "--words":   i += 1; if i < args.count, let v = Int(args[i]) { words = max(2, min(6, v)) }
        case "--max-len": i += 1; if i < args.count, let v = Int(args[i]) { maxLen = max(3, min(8, v)) }
        default: break
        }
        i += 1
    }

    print(MeowPass.meowKey(words: words, maxLen: maxLen))
}

/**
 * Display help information for command-line usage
 * Shows all available options and example usage
 */
func showHelp() {
    print("MeowPassword - Cat Dynamic Secure Password Generator")
    print("")
    print("Usage: meowpass [subcommand] [options]")
    print("")
    print("Password generation options:")
    print("  --numbers N          Number of random numbers to insert (1-10, default: 1-4)")
    print("  --symbols N          Number of symbols to insert (1-10, default: 2)")
    print("  --max-length N       Maximum password length (15-50, default: 25)")
    print("  --test               Run tests")
    print("  --copy               Copy password to clipboard (pbcopy / xclip / wl-copy)")
    print("  --psssst, -p         Copy password to clipboard without displaying it")
    print("                       (more secure - password won't be shown in clear text)")
    print("  --analyze, -a S      Analyze a string's meow complexity (treats it like a password)")
    print("  --update             Check GitHub for updates and install if available")
    print("  --save-to-keychain   Save password to Apple Keychain (macOS only)")
    print("  --service <name>     Keychain service name (default: MeowPassword)")
    print("  --account <name>     Keychain account name (default: generated)")
    print("  --help, -h           Show this help message")
    print("")
    print("StegoMeow subcommands (cat-image passkeys):")
    print("  steg-embed  --in <image.pgm|png|gif|jpg|jpeg> --out <stego.pgm|png|gif>")
    print("              --payload-file <file> --wm-key hex:<hex>|<passphrase>")
    print("              [--qim-step <N>]")
    print("  steg-extract --in <image.pgm|png|gif|jpg|jpeg> --wm-key hex:<hex>|<passphrase>")
    print("               [--raw] [--qim-step <N>]")
    print("")
    print("MeowGram subcommands (color cat-mail with a hidden provenance key):")
    print("  meowgram-prep  [--in-dir <dir>] [--out-dir <dir>] [--manifest <path>]")
    print("                 [--size <WxH>] [--verify|--no-verify] [--force]")
    print("                 Bakes a provenance GUID into each source image.")
    print("  meowgram-embed --in <keyed.png> --out <mail.png> --message-file <f>")
    print("                 [--passphrase <p>]   Embeds a message (PNG output only).")
    print("  meowgram-read  --in <mail.png> [--passphrase <p>]   Reads GUID + message.")
    print("  meow-key       [--words N] [--max-len L]   Voice-friendly cat passphrase")
    print("                 (e.g. tom-max-luna) from short embedded cat names.")
    print("")
    print("Examples:")
    print("  meowpass")
    print("  meowpass --numbers 4 --symbols 3 --max-length 30")
    print("  meowpass --analyze \"MyP@ssw0rd!\"")
    print("  meowpass --test")
    print("  meowpass --save-to-keychain --service com.example.myapp --account alice")
    print("  meowpass steg-embed --in cat.pgm --out auth.pgm --payload-file token.jwt --wm-key hex:001122aabb")
    print("  meowpass steg-embed --in cat.png --out auth.png --payload-file token.jwt --wm-key hex:001122aabb")
    print("  meowpass steg-embed --in cat.gif --out auth.gif --payload-file token.jwt --wm-key hex:001122aabb")
    print("  meowpass steg-extract --in auth.pgm --wm-key hex:001122aabb")
    print("  meowpass steg-extract --in auth.png --wm-key hex:001122aabb")
}

// MARK: - Clipboard

/**
 * Copy the given string to the system clipboard.
 * macOS: pbcopy. Linux: xclip, else wl-copy.
 * Returns true on success, false if no clipboard tool is available.
 */
@discardableResult
func copyToClipboard(_ text: String) -> Bool {
    #if os(macOS)
    return runPipe(command: "/usr/bin/pbcopy", arguments: [], input: text)
    #elseif os(Linux)
    if let xclip = which("xclip") {
        return runPipe(command: xclip, arguments: ["-selection", "clipboard"], input: text)
    }
    if let wlCopy = which("wl-copy") {
        return runPipe(command: wlCopy, arguments: [], input: text)
    }
    return false
    #else
    return false
    #endif
}

/**
 * Pipe `input` into the given command's stdin. Returns true if exit code == 0.
 */
private func runPipe(command: String, arguments: [String], input: String) -> Bool {
    let task = Process()
    task.launchPath = command
    task.arguments = arguments
    let pipe = Pipe()
    task.standardInput = pipe
    do {
        try task.run()
    } catch {
        return false
    }
    if let data = input.data(using: .utf8) {
        pipe.fileHandleForWriting.write(data)
    }
    pipe.fileHandleForWriting.closeFile()
    task.waitUntilExit()
    return task.terminationStatus == 0
}

#if os(Linux)
/**
 * Resolve `name` via `command -v`. Returns the path or nil if not found.
 */
private func which(_ name: String) -> String? {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", "command -v \(name)"]
    let pipe = Pipe()
    task.standardOutput = pipe
    do {
        try task.run()
    } catch {
        return nil
    }
    task.waitUntilExit()
    guard task.terminationStatus == 0 else { return nil }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    return (path?.isEmpty == false) ? path : nil
}
#endif

func clipboardMissingHint() -> String {
    #if os(macOS)
    return "Clipboard functionality requires pbcopy (default on macOS)"
    #elseif os(Linux)
    return "Clipboard functionality requires xclip or wl-copy (apt install xclip)"
    #else
    return "Clipboard functionality is not supported on this platform"
    #endif
}

// MARK: - Update Check

/**
 * Compare two dotted version strings ("1.2.3" vs "1.2.4").
 * Returns 1 if latest > current, 0 if equal, -1 if latest < current.
 */
func compareVersions(_ current: String, _ latest: String) -> Int {
    let cur = current.split(separator: ".").map { Int($0) ?? 0 }
    let lat = latest.split(separator: ".").map { Int($0) ?? 0 }
    let count = max(cur.count, lat.count)
    for i in 0..<count {
        let c = i < cur.count ? cur[i] : 0
        let l = i < lat.count ? lat[i] : 0
        if l != c { return l > c ? 1 : -1 }
    }
    return 0
}

/**
 * Extract the tag_name value from a GitHub release JSON blob.
 * Strips a leading "v" if present.
 */
func parseTagFromJSON(_ json: String) -> String? {
    guard let range = json.range(of: "\"tag_name\"") else { return nil }
    var rest = json[range.upperBound...]
    // Skip whitespace and colon
    while let c = rest.first, c == " " || c == "\t" || c == ":" {
        rest = rest.dropFirst()
    }
    guard rest.first == "\"" else { return nil }
    rest = rest.dropFirst()
    if let c = rest.first, c == "v" || c == "V" {
        rest = rest.dropFirst()
    }
    guard let endQuote = rest.firstIndex(of: "\"") else { return nil }
    let tag = String(rest[..<endQuote])
    return tag.isEmpty ? nil : tag
}

/**
 * A version string is valid if it contains only digits and dots.
 */
func isValidVersion(_ v: String) -> Bool {
    guard !v.isEmpty else { return false }
    return v.allSatisfy { $0.isNumber || $0 == "." }
}

/**
 * Run a shell command and capture stdout. Returns nil on failure.
 */
private func shellCapture(_ command: String) -> String? {
    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", command]
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = FileHandle.standardError
    do {
        try task.run()
    } catch {
        return nil
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    guard task.terminationStatus == 0 else { return nil }
    return String(data: data, encoding: .utf8)
}

/**
 * Check GitHub releases for a newer version and optionally install it.
 * Returns 0 on success (or no update), non-zero on error.
 */
func checkForUpdate() -> Int32 {
    print("Checking for updates...")

    let url = "https://api.github.com/repos/\(meowpassGithubOwner)/\(meowpassGithubRepo)/releases/latest"
    guard let response = shellCapture("curl -s '\(url)'"), !response.isEmpty else {
        FileHandle.standardError.write("Error: No response from GitHub API.\n".data(using: .utf8)!)
        return -1
    }

    guard let latest = parseTagFromJSON(response) else {
        FileHandle.standardError.write("Error: Could not parse version from GitHub response.\n".data(using: .utf8)!)
        return -1
    }

    guard isValidVersion(latest) else {
        FileHandle.standardError.write("Error: Invalid version format received from GitHub.\n".data(using: .utf8)!)
        return -1
    }

    print("Current version: \(meowpassVersion)")
    print("Latest  version: \(latest)")

    if compareVersions(meowpassVersion, latest) <= 0 {
        print("You are already running the latest version. Meow!")
        return 0
    }

    print("")
    print("A new version (\(latest)) is available!")
    print("Would you like to download, build, and install it? [y/N] ", terminator: "")

    guard let line = readLine(), let first = line.first, first == "y" || first == "Y" else {
        print("Update skipped.")
        return 0
    }

    let installCmd = """
    set -e && \
    TMPDIR=$(mktemp -d) && \
    echo "Downloading v\(latest)..." && \
    curl -sL https://github.com/\(meowpassGithubOwner)/\(meowpassGithubRepo)/archive/refs/tags/v\(latest).tar.gz | tar xz -C "$TMPDIR" && \
    echo "Building..." && \
    (cd "$TMPDIR/\(meowpassGithubRepo)-\(latest)" && swift build -c release) && \
    echo "Installing (may require sudo)..." && \
    sudo install "$TMPDIR/\(meowpassGithubRepo)-\(latest)/.build/release/meowpass" /usr/local/bin/meowpass && \
    rm -rf "$TMPDIR" && \
    echo "Update complete! Meow!"
    """

    let task = Process()
    task.launchPath = "/bin/sh"
    task.arguments = ["-c", installCmd]
    do {
        try task.run()
    } catch {
        FileHandle.standardError.write("Error: Update failed to launch.\n".data(using: .utf8)!)
        return -1
    }
    task.waitUntilExit()
    return task.terminationStatus == 0 ? 0 : -1
}

// MARK: - Main Program
func main() -> Int32 {
    let args = CommandLine.arguments

    // Route steg subcommands before other option parsing.
    if args.count >= 2 && args[1] == "steg-embed" {
        runStegoEmbed(args: Array(args.dropFirst(2)))
        return 0
    }
    if args.count >= 2 && args[1] == "steg-extract" {
        runStegoExtract(args: Array(args.dropFirst(2)))
        return 0
    }
    if args.count >= 2 && args[1] == "meow-key" {
        runMeowKey(args: Array(args.dropFirst(2)))
        return 0
    }
    #if os(macOS)
    if args.count >= 2 && args[1] == "meowgram-prep" {
        runMeowgramPrep(args: Array(args.dropFirst(2)))
        return 0
    }
    if args.count >= 2 && args[1] == "meowgram-embed" {
        runMeowgramEmbed(args: Array(args.dropFirst(2)))
        return 0
    }
    if args.count >= 2 && args[1] == "meowgram-read" {
        runMeowgramRead(args: Array(args.dropFirst(2)))
        return 0
    }
    #endif

    let config = PasswordConfig(arguments: args)

    if config.showHelp {
        showHelp()
        return 0
    }

    if config.showTests {
        runBasicTests()
        return 0
    }

    if config.checkUpdate {
        return checkForUpdate()
    }

    // Analyze mode: score any input string
    if let input = config.analyzeString {
        print(lolcatArt)
        print("Meow Analyzing your string for cat-cracking resistance...")
        print("")
        let (_, analysis, verdict) = MeowPass.analyze(input)
        print(analysis)
        print("")
        print(verdict)
        return 0
    }

    // Load cat names (now from embedded data)
    let catNames = MeowPass.catNames()
    guard !catNames.isEmpty else {
        FileHandle.standardError.write("ERROR: No cat names loaded from embedded data.\n".data(using: .utf8)!)
        return 1
    }

    // Silent mode: generate, copy best to clipboard, print nothing sensitive
    if config.psssst {
        let best = MeowPass.best(config: coreConfig(config), count: 5)
        if copyToClipboard(best.password) {
            print("----> copied!")
        } else {
            print(clipboardMissingHint())
            return 1
        }
        return 0
    }

    // Show ASCII art and title
    print(lolcatArt)
    print("Meow Password - Cat Name Based Secure Password Generator")
    print("========================================================")

    print("Loaded \(catNames.count) meow cat names")
    print("Generating 5 secure password meow candidates...")
    print("Config: \(config.numNumbers) numbers, \(config.numSymbols) symbols, max meow length \(config.maxLength)")
    print("")

    // Generate 5 password candidates
    let candidates = MeowPass.generate(config: coreConfig(config), count: 5)

    for (i, candidate) in candidates.enumerated() {
        print("Candidate \(i + 1): \(candidate.password)")
        print("   Meow Score: \(String(format: "%.2f", candidate.score))/10.0")
        print("")
    }

    // Select the most secure password
    guard let bestCandidate = candidates.max(by: { $0.score < $1.score }) else {
        print("ERROR: Could not meow select best password")
        return 1
    }

    print("MOST SECURE PASSWORD MEOW SELECTED:")
    print("Password: \(bestCandidate.password)")
    print("Final Meow Score: \(String(format: "%.2f", bestCandidate.score))/10.0")
    print("")
    print(bestCandidate.analysis)

    if config.copyToClipboard {
        print("")
        if copyToClipboard(bestCandidate.password) {
            print("Password copied to clipboard!")
        } else {
            print(clipboardMissingHint())
        }
    } else {
        print("")
        print("Use 'meowpass --copy' to copy password to clipboard")
    }

    // Option to save to Apple Keychain
    if config.saveToKeychain {
        #if os(macOS)
        if savePasswordToKeychain(password: bestCandidate.password,
                                  service: config.keychainService,
                                  account: config.keychainAccount) {
            print("")
            print("Password saved to Apple Keychain (service: \(config.keychainService), account: \(config.keychainAccount))")
        } else {
            print("")
            print("WARNING: Failed to save password to Apple Keychain")
        }
        #else
        print("")
        print("Apple Keychain integration is only available on macOS")
        #endif
    }

    return 0
}

// Run the program
exit(main())

