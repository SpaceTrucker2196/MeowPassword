// Sources/MeowUI/ThemedBackground.swift
//
// The full-screen stage behind every screen, switched by the active theme's
// background motif (docs/themes/*: "Background motif" token). First-pass
// implementations: each motif is a cheap Canvas/gradient composition — the
// era-specific art (mosaic crowds, photomontage cats) comes later.

import SwiftUI

public struct ThemedBackground: View {
    @Environment(\.theme) private var theme

    public init() {}

    public var body: some View {
        switch theme.motif {
        case .neonGradient:     neonGradient
        case .sunburstHalftone: sunburstHalftone
        case .reticleNight:     reticleNight
        case .wedgeRays:        wedgeRays
        case .sunrise:          sunrise
        }
    }

    // MARK: GameShow Classic — the original pink→purple sweep, byte-exact.

    private var neonGradient: some View {
        LinearGradient(
            colors: [theme.command, theme.commandDeep, Color(hex: 0x591A8C)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    // MARK: Shōwa — flat cream + rounded sunburst fan from the top + halftone.

    private var sunburstHalftone: some View {
        ZStack {
            theme.floor
            Canvas { ctx, size in
                // Sunburst: alternating mustard wedges fanning from top center,
                // low opacity so content shouts over it.
                let center = CGPoint(x: size.width / 2, y: -size.height * 0.15)
                let radius = max(size.width, size.height) * 1.4
                let wedges = 18
                for i in 0..<wedges where i.isMultiple(of: 2) {
                    let a0 = Double(i) / Double(wedges) * 2 * .pi
                    let a1 = Double(i + 1) / Double(wedges) * 2 * .pi
                    var path = Path()
                    path.move(to: center)
                    path.addArc(center: center, radius: radius,
                                startAngle: .radians(a0), endAngle: .radians(a1),
                                clockwise: false)
                    path.closeSubpath()
                    ctx.fill(path, with: .color(theme.celebrate.opacity(0.10)))
                }
                // Halftone "studio audience" dots along the bottom, ink at
                // the spec's 12–18% ceiling.
                let dot: CGFloat = 3, gap: CGFloat = 14
                let rows = 6
                for r in 0..<rows {
                    let y = size.height - CGFloat(r) * gap - 24
                    let fade = 0.14 * (1 - Double(r) / Double(rows))
                    var x: CGFloat = (r.isMultiple(of: 2) ? 0 : gap / 2) + 12
                    while x < size.width {
                        ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: dot, height: dot)),
                                 with: .color(theme.bind.opacity(fade)))
                        x += gap
                    }
                }
            }
        }
    }

    // MARK: Spy — the night, a gold glint, a faint reticle. No glow.

    private var reticleNight: some View {
        ZStack {
            theme.floor
            Canvas { ctx, size in
                // Fine reticle grid, barely there.
                let step: CGFloat = 44
                var x: CGFloat = step
                while x < size.width {
                    ctx.stroke(Path { $0.move(to: CGPoint(x: x, y: 0))
                                      $0.addLine(to: CGPoint(x: x, y: size.height)) },
                               with: .color(theme.seal.opacity(0.035)), lineWidth: 0.5)
                    x += step
                }
                var y: CGFloat = step
                while y < size.height {
                    ctx.stroke(Path { $0.move(to: CGPoint(x: 0, y: y))
                                      $0.addLine(to: CGPoint(x: size.width, y: y)) },
                               with: .color(theme.seal.opacity(0.035)), lineWidth: 0.5)
                    y += step
                }
                // The single hard gold diagonal — a cufflink catching light.
                var glint = Path()
                glint.move(to: CGPoint(x: -20, y: size.height * 0.82))
                glint.addLine(to: CGPoint(x: size.width + 20, y: size.height * 0.18))
                ctx.stroke(glint, with: .color(theme.command.opacity(0.35)), lineWidth: 1.5)
            }
        }
    }

    // MARK: Kremlin — newsprint with sharp red wedge rays marching upward.

    private var wedgeRays: some View {
        ZStack {
            theme.floor
            Canvas { ctx, size in
                // Angular rays fanning from the bottom-left corner.
                let origin = CGPoint(x: -size.width * 0.1, y: size.height * 1.1)
                let reach = max(size.width, size.height) * 1.8
                let rays = 7
                for i in 0..<rays {
                    // Sweep from -80° to -10° (up-and-right), thin wedges.
                    let a0 = (-80.0 + Double(i) * 10.0) * .pi / 180
                    let a1 = a0 + 3.5 * .pi / 180
                    var path = Path()
                    path.move(to: origin)
                    path.addLine(to: CGPoint(x: origin.x + Foundation.cos(a0) * reach,
                                             y: origin.y + Foundation.sin(a0) * reach))
                    path.addLine(to: CGPoint(x: origin.x + Foundation.cos(a1) * reach,
                                             y: origin.y + Foundation.sin(a1) * reach))
                    path.closeSubpath()
                    ctx.fill(path, with: .color(theme.command.opacity(0.12)))
                }
            }
        }
    }

    // MARK: Pyongyang — dawn rose, gold beams, the one allowed soft glow.

    private var sunrise: some View {
        ZStack {
            theme.floor
            // The permitted softness: a gentle radial sky glow behind the sun.
            RadialGradient(colors: [theme.celebrate.opacity(0.45), .clear],
                           center: .init(x: 0.5, y: 0.12),
                           startRadius: 0, endRadius: 420)
            Canvas { ctx, size in
                // Long gold beams radiating from the high-center sun.
                let center = CGPoint(x: size.width / 2, y: size.height * 0.08)
                let reach = max(size.width, size.height) * 1.6
                let beams = 12
                for i in 0..<beams {
                    // Fan across the lower half-plane.
                    let a0 = (Double(i) / Double(beams)) * .pi + 0.02
                    let a1 = a0 + 0.06
                    var path = Path()
                    path.move(to: center)
                    path.addLine(to: CGPoint(x: center.x + Foundation.cos(a0) * reach,
                                             y: center.y + Foundation.sin(a0) * reach))
                    path.addLine(to: CGPoint(x: center.x + Foundation.cos(a1) * reach,
                                             y: center.y + Foundation.sin(a1) * reach))
                    path.closeSubpath()
                    ctx.fill(path, with: .color(theme.celebrate.opacity(0.16)))
                }
            }
        }
    }
}
