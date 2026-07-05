// Sources/MeowStego/YCbCr.swift

/// Full-range BT.601 conversion between packed 8-bit RGB and separate
/// luma / chroma planes.
///
/// MeowGram embeds only in the luma (Y) plane so the cat image stays in
/// color. The chroma planes are carried as `Float` and never quantized during
/// an embed round-trip — only the final `toRGB` call rounds back to bytes —
/// so recombining a stego'd Y with the original Cb/Cr reproduces the image
/// with just the intended luma perturbation.
///
/// This is pure arithmetic (no platform frameworks) so it can be unit-tested
/// anywhere. The coefficients match the `rgbToLuma` BT.601 luma used elsewhere.
public enum YCbCr {

    /// Split packed RGB (`[r,g,b, r,g,b, …]`, `3 * pixelCount` bytes) into an
    /// 8-bit luma plane and full-precision chroma planes.
    public static func fromRGB(
        rgb: [UInt8], pixelCount: Int
    ) -> (y: [UInt8], cb: [Float], cr: [Float]) {
        var y  = [UInt8](repeating: 0, count: pixelCount)
        var cb = [Float](repeating: 0, count: pixelCount)
        var cr = [Float](repeating: 0, count: pixelCount)
        for i in 0..<pixelCount {
            let r = Float(rgb[i * 3 + 0])
            let g = Float(rgb[i * 3 + 1])
            let b = Float(rgb[i * 3 + 2])
            let luma = 0.299 * r + 0.587 * g + 0.114 * b
            y[i]  = UInt8(min(255, max(0, Int(luma.rounded()))))
            cb[i] = 128.0 - 0.168736 * r - 0.331264 * g + 0.5      * b
            cr[i] = 128.0 + 0.5      * r - 0.418688 * g - 0.081312 * b
        }
        return (y, cb, cr)
    }

    /// Recombine a (possibly modified) luma plane with full-precision chroma
    /// planes back into packed 8-bit RGB.
    public static func toRGB(y: [UInt8], cb: [Float], cr: [Float]) -> [UInt8] {
        let pixelCount = y.count
        var rgb = [UInt8](repeating: 0, count: pixelCount * 3)
        for i in 0..<pixelCount {
            let yy = Float(y[i])
            let cbd = cb[i] - 128.0
            let crd = cr[i] - 128.0
            let r = yy + 1.402 * crd
            let g = yy - 0.344136 * cbd - 0.714136 * crd
            let b = yy + 1.772 * cbd
            rgb[i * 3 + 0] = UInt8(min(255, max(0, Int(r.rounded()))))
            rgb[i * 3 + 1] = UInt8(min(255, max(0, Int(g.rounded()))))
            rgb[i * 3 + 2] = UInt8(min(255, max(0, Int(b.rounded()))))
        }
        return rgb
    }
}
