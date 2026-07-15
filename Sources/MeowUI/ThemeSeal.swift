// Sources/MeowUI/ThemeSeal.swift
//
// The signature approval stamp — "the producer's approval pressed onto every
// frame" (docs/DESIGN.md). Each theme supplies its own mark: the Shōwa hanko
// ring, Spy's gun-barrel iris, Kremlin's five-point star, Pyongyang's
// flower-burst rosette. Tilted ~8° per the house laws; flat print, no glow.

import SwiftUI

public struct ThemeSeal: View {
    @Environment(\.theme) private var theme
    var size: CGFloat

    public init(size: CGFloat = 72) {
        self.size = size
    }

    public var body: some View {
        ZStack {
            switch theme.sealStyle {
            case .hanko:   hanko
            case .iris:    iris
            case .star:    star
            case .rosette: rosette
            }
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(8))
        .allowsHitTesting(false)
        .accessibilityLabel(Text(theme.sealCaption))
    }

    /// "認証成功" / "MEOW VERIFIED" split back into its two voices.
    private var captionLines: [String] {
        theme.sealCaption.components(separatedBy: " · ")
    }

    private func caption(_ color: Color, scale: CGFloat = 1) -> some View {
        VStack(spacing: 1) {
            ForEach(captionLines, id: \.self) { line in
                Text(line)
                    .font(.system(size: size * 0.09 * scale, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .foregroundStyle(color)
        .padding(.horizontal, size * 0.12)
    }

    // Shōwa/Classic: a circular ink seal, ring + caption, one color like a
    // real stamp pad.
    private var hanko: some View {
        ZStack {
            Circle().stroke(theme.seal, lineWidth: size * 0.055)
            Circle().stroke(theme.seal, lineWidth: size * 0.014)
                .padding(size * 0.09)
            caption(theme.seal)
        }
    }

    // Spy: concentric gun-barrel rings, onyx grooves on gun-barrel white,
    // the caption clinical in the middle.
    private var iris: some View {
        ZStack {
            Circle().fill(theme.seal)
            ForEach(0..<3, id: \.self) { ring in
                Circle().stroke(theme.bind, lineWidth: size * 0.02)
                    .padding(size * (0.05 + CGFloat(ring) * 0.09))
            }
            Circle().fill(theme.seal)
                .padding(size * 0.30)
            caption(theme.bind, scale: 0.9)
        }
    }

    // Kremlin: the five-point star, caption punched out in newsprint.
    private var star: some View {
        ZStack {
            StarShape().fill(theme.seal)
            StarShape().stroke(theme.bind, lineWidth: size * 0.02)
            caption(theme.floor, scale: 0.62)
                .offset(y: -size * 0.01)
        }
    }

    // Pyongyang: a flower-burst rosette — petals, gold heart, ink caption.
    private var rosette: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { petal in
                Capsule()
                    .fill(theme.seal)
                    .frame(width: size * 0.24, height: size * 0.52)
                    .offset(y: -size * 0.24)
                    .rotationEffect(.degrees(Double(petal) * 36))
            }
            Circle().fill(theme.celebrate)
                .padding(size * 0.22)
                .overlay(Circle().stroke(theme.bind, lineWidth: size * 0.02)
                    .padding(size * 0.22))
            caption(theme.bind, scale: 0.75)
        }
    }
}

/// A crisp five-point star centered in its rect.
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.42
        var path = Path()
        for i in 0..<10 {
            let angle = Double(i) * .pi / 5 - .pi / 2
            let radius = i.isMultiple(of: 2) ? outer : inner
            let point = CGPoint(x: center.x + Foundation.cos(angle) * radius,
                                y: center.y + Foundation.sin(angle) * radius)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}
