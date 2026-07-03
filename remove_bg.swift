// Foreground isolation via macOS Vision.
// Usage: swift remove_bg.swift <in.jpg> <out.png>

import Foundation
import Vision
import CoreImage
import AppKit

guard CommandLine.arguments.count >= 3 else {
    FileHandle.standardError.write("usage: remove_bg.swift <in> <out>\n".data(using: .utf8)!)
    exit(2)
}

let src = URL(fileURLWithPath: CommandLine.arguments[1])
let dst = URL(fileURLWithPath: CommandLine.arguments[2])

guard let img = NSImage(contentsOf: src),
      let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    FileHandle.standardError.write("could not read image\n".data(using: .utf8)!)
    exit(1)
}

let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
let req = VNGenerateForegroundInstanceMaskRequest()
try handler.perform([req])

guard let obs = req.results?.first else {
    FileHandle.standardError.write("no foreground detected\n".data(using: .utf8)!)
    exit(1)
}

let maskedBuffer = try obs.generateMaskedImage(
    ofInstances: obs.allInstances,
    from: handler,
    croppedToInstancesExtent: true
)

let ciImage = CIImage(cvPixelBuffer: maskedBuffer)
let context = CIContext()
guard let outCG = context.createCGImage(ciImage, from: ciImage.extent) else {
    FileHandle.standardError.write("could not build CGImage\n".data(using: .utf8)!)
    exit(1)
}

let rep = NSBitmapImageRep(cgImage: outCG)
guard let data = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("png encode failed\n".data(using: .utf8)!)
    exit(1)
}

try data.write(to: dst)
print("wrote \(dst.path) (\(outCG.width)x\(outCG.height))")
