// Feather PNG alpha edges via a small Gaussian blur.
// Usage: swift soften_edges.swift <in.png> <out.png> [radius]

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit

guard CommandLine.arguments.count >= 3 else {
    FileHandle.standardError.write("usage: soften_edges.swift <in> <out> [radius]\n".data(using: .utf8)!)
    exit(2)
}

let src = URL(fileURLWithPath: CommandLine.arguments[1])
let dst = URL(fileURLWithPath: CommandLine.arguments[2])
let radius = CommandLine.arguments.count >= 4 ? Double(CommandLine.arguments[3]) ?? 2.0 : 2.0

guard let data = try? Data(contentsOf: src),
      let ciImage = CIImage(data: data) else {
    FileHandle.standardError.write("could not read image\n".data(using: .utf8)!)
    exit(1)
}

// Isolate the alpha channel and blur only that. Recompose with the
// original RGB so the interior stays sharp — only the mask edges soften.
let alphaMatrix = CIFilter.colorMatrix()
alphaMatrix.inputImage = ciImage
alphaMatrix.rVector = CIVector(x: 0, y: 0, z: 0, w: 1)
alphaMatrix.gVector = CIVector(x: 0, y: 0, z: 0, w: 1)
alphaMatrix.bVector = CIVector(x: 0, y: 0, z: 0, w: 1)
alphaMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
alphaMatrix.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)
guard let alphaOnly = alphaMatrix.outputImage else { exit(1) }

let blur = CIFilter.gaussianBlur()
blur.inputImage = alphaOnly
blur.radius = Float(radius)
guard let blurred = blur.outputImage?.cropped(to: ciImage.extent) else { exit(1) }

// Convert the blurred greyscale back to a pure alpha mask.
let toAlpha = CIFilter.colorMatrix()
toAlpha.inputImage = blurred
toAlpha.rVector = CIVector(x: 0, y: 0, z: 0, w: 0)
toAlpha.gVector = CIVector(x: 0, y: 0, z: 0, w: 0)
toAlpha.bVector = CIVector(x: 0, y: 0, z: 0, w: 0)
toAlpha.aVector = CIVector(x: 1, y: 0, z: 0, w: 0)
toAlpha.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)
guard let softAlpha = toAlpha.outputImage else { exit(1) }

// Multiply original RGBA by the soft-alpha mask — this feathers edges.
let blend = CIFilter.multiplyCompositing()
blend.inputImage = ciImage
blend.backgroundImage = softAlpha
guard let feathered = blend.outputImage?.cropped(to: ciImage.extent) else { exit(1) }

let ctx = CIContext()
guard let cg = ctx.createCGImage(feathered, from: feathered.extent) else {
    FileHandle.standardError.write("createCGImage failed\n".data(using: .utf8)!)
    exit(1)
}
let rep = NSBitmapImageRep(cgImage: cg)
guard let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: dst)
print("wrote \(dst.path) (\(cg.width)x\(cg.height), radius \(radius))")
