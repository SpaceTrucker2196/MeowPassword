// Sources/MeowGramKit/ColorImageIO.swift

#if os(macOS)
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Color (24-bit RGB) image I/O for MeowGram. Kept separate from the CLI's
/// grayscale `readGrayImage`, whose gamma-aware DeviceGray conversion is *not*
/// BT.601 and would shift luma enough to break QIM extraction. MeowGram always
/// goes RGB → `YCbCr.fromRGB` for a byte-exact luma plane.
public enum ColorImageIO {

    public struct RGBImage {
        public var rgb: [UInt8]   // packed [r,g,b, …], row-major, 3*w*h bytes
        public var width: Int
        public var height: Int
        public init(rgb: [UInt8], width: Int, height: Int) {
            self.rgb = rgb; self.width = width; self.height = height
        }
        public var pixelCount: Int { width * height }
    }

    public enum IOError: Error, CustomStringConvertible {
        case cannotRead(String)
        case cannotDecode(String)
        case cannotWrite(String)
        public var description: String {
            switch self {
            case .cannotRead(let p):   return "Cannot read image at \(p)"
            case .cannotDecode(let p): return "Cannot decode image at \(p)"
            case .cannotWrite(let p):  return "Cannot write PNG at \(p)"
            }
        }
    }

    /// Load any ImageIO-decodable file (JPEG/PNG/…) as packed 24-bit RGB.
    public static func readRGBImage(path: String) throws -> RGBImage {
        let url = URL(fileURLWithPath: path) as CFURL
        guard let source = CGImageSourceCreateWithURL(url, nil) else {
            throw IOError.cannotRead(path)
        }
        guard let cg = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw IOError.cannotDecode(path)
        }
        return try rgb(from: cg)
    }

    /// Rasterize a `CGImage` into packed 24-bit RGB via an sRGB context.
    public static func rgb(from cg: CGImage) throws -> RGBImage {
        let width = cg.width
        let height = cg.height
        // Draw into RGBA8 then drop alpha — CoreGraphics has no 24-bit RGB
        // context, but premultiplied-none over an opaque image is lossless.
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        var rgba = [UInt8](repeating: 0, count: width * height * 4)
        guard let ctx = CGContext(
            data: &rgba, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { throw IOError.cannotDecode("<cgimage>") }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))

        var rgb = [UInt8](repeating: 0, count: width * height * 3)
        for i in 0..<(width * height) {
            rgb[i * 3 + 0] = rgba[i * 4 + 0]
            rgb[i * 3 + 1] = rgba[i * 4 + 1]
            rgb[i * 3 + 2] = rgba[i * 4 + 2]
        }
        return RGBImage(rgb: rgb, width: width, height: height)
    }

    /// Write packed 24-bit RGB to a lossless PNG.
    @discardableResult
    public static func writePNG(_ image: RGBImage, to path: String) throws -> Bool {
        let w = image.width, h = image.height
        var rgba = [UInt8](repeating: 255, count: w * h * 4)
        for i in 0..<(w * h) {
            rgba[i * 4 + 0] = image.rgb[i * 3 + 0]
            rgba[i * 4 + 1] = image.rgb[i * 3 + 1]
            rgba[i * 4 + 2] = image.rgb[i * 3 + 2]
            rgba[i * 4 + 3] = 255
        }
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let provider = CGDataProvider(data: Data(rgba) as CFData),
              let cg = CGImage(
                  width: w, height: h,
                  bitsPerComponent: 8, bitsPerPixel: 32,
                  bytesPerRow: w * 4, space: colorSpace,
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                  provider: provider, decode: nil, shouldInterpolate: false,
                  intent: .defaultIntent
              ) else { throw IOError.cannotWrite(path) }
        let url = URL(fileURLWithPath: path) as CFURL
        guard let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)
        else { throw IOError.cannotWrite(path) }
        CGImageDestinationAddImage(dest, cg, nil)
        guard CGImageDestinationFinalize(dest) else { throw IOError.cannotWrite(path) }
        return true
    }

    /// Encode packed 24-bit RGB to in-memory PNG `Data` (for the app's
    /// preview / share path, which never touches disk with the raw bytes).
    public static func pngData(_ image: RGBImage) throws -> Data {
        let w = image.width, h = image.height
        var rgba = [UInt8](repeating: 255, count: w * h * 4)
        for i in 0..<(w * h) {
            rgba[i * 4 + 0] = image.rgb[i * 3 + 0]
            rgba[i * 4 + 1] = image.rgb[i * 3 + 1]
            rgba[i * 4 + 2] = image.rgb[i * 3 + 2]
            rgba[i * 4 + 3] = 255
        }
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let provider = CGDataProvider(data: Data(rgba) as CFData),
              let cg = CGImage(
                  width: w, height: h,
                  bitsPerComponent: 8, bitsPerPixel: 32,
                  bytesPerRow: w * 4, space: colorSpace,
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                  provider: provider, decode: nil, shouldInterpolate: false,
                  intent: .defaultIntent
              ) else { throw IOError.cannotWrite("<data>") }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)
        else { throw IOError.cannotWrite("<data>") }
        CGImageDestinationAddImage(dest, cg, nil)
        guard CGImageDestinationFinalize(dest) else { throw IOError.cannotWrite("<data>") }
        return data as Data
    }

    /// Center-crop `image` to the aspect ratio of `targetW × targetH`, then
    /// scale to exactly that size using a high-quality CoreGraphics resample.
    /// All geometry must happen *before* embedding — any later resize destroys
    /// the payload.
    public static func cropAndScale(
        _ image: RGBImage, targetW: Int, targetH: Int
    ) throws -> RGBImage {
        // 1. Center crop to target aspect ratio.
        let srcW = image.width, srcH = image.height
        let targetAspect = Double(targetW) / Double(targetH)
        let srcAspect = Double(srcW) / Double(srcH)
        var cropW = srcW, cropH = srcH
        if srcAspect > targetAspect {
            cropW = Int((Double(srcH) * targetAspect).rounded())
        } else {
            cropH = Int((Double(srcW) / targetAspect).rounded())
        }
        let originX = (srcW - cropW) / 2
        let originY = (srcH - cropH) / 2

        // 2. Build a source CGImage and draw the cropped region scaled to target.
        let cg = try cgImage(from: image)
        let cropRect = CGRect(x: originX, y: originY, width: cropW, height: cropH)
        guard let cropped = cg.cropping(to: cropRect) else {
            throw IOError.cannotDecode("<crop>")
        }
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        var rgba = [UInt8](repeating: 0, count: targetW * targetH * 4)
        guard let ctx = CGContext(
            data: &rgba, width: targetW, height: targetH,
            bitsPerComponent: 8, bytesPerRow: targetW * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { throw IOError.cannotDecode("<scale>") }
        ctx.interpolationQuality = .high
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: CGFloat(targetW), height: CGFloat(targetH)))

        var out = [UInt8](repeating: 0, count: targetW * targetH * 3)
        for i in 0..<(targetW * targetH) {
            out[i * 3 + 0] = rgba[i * 4 + 0]
            out[i * 3 + 1] = rgba[i * 4 + 1]
            out[i * 3 + 2] = rgba[i * 4 + 2]
        }
        return RGBImage(rgb: out, width: targetW, height: targetH)
    }

    /// Build an opaque `CGImage` from packed 24-bit RGB.
    private static func cgImage(from image: RGBImage) throws -> CGImage {
        let w = image.width, h = image.height
        var rgba = [UInt8](repeating: 255, count: w * h * 4)
        for i in 0..<(w * h) {
            rgba[i * 4 + 0] = image.rgb[i * 3 + 0]
            rgba[i * 4 + 1] = image.rgb[i * 3 + 1]
            rgba[i * 4 + 2] = image.rgb[i * 3 + 2]
            rgba[i * 4 + 3] = 255
        }
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        guard let provider = CGDataProvider(data: Data(rgba) as CFData),
              let cg = CGImage(
                  width: w, height: h,
                  bitsPerComponent: 8, bitsPerPixel: 32,
                  bytesPerRow: w * 4, space: colorSpace,
                  bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                  provider: provider, decode: nil, shouldInterpolate: false,
                  intent: .defaultIntent
              ) else { throw IOError.cannotDecode("<cgimage>") }
        return cg
    }
}
#endif
