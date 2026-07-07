// Sources/MeowUI/MeowUI.swift
//
// Portable SwiftUI design system shared by the macOS and iOS apps. Pure
// SwiftUI (Color / Shape / Canvas) — no AppKit or UIKit — so both apps render
// the same game-show look.

import SwiftUI
import QuartzCore
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Palette

public enum GameShow {
    public static let hotPink    = Color(red: 1.00, green: 0.24, blue: 0.63)
    public static let magenta    = Color(red: 0.69, green: 0.13, blue: 0.56)
    public static let neonYellow = Color(red: 1.00, green: 0.92, blue: 0.00)
    public static let neonCyan   = Color(red: 0.00, green: 0.90, blue: 1.00)
    public static let neonLime   = Color(red: 0.65, green: 1.00, blue: 0.20)
    public static let inkBlack   = Color(red: 0.09, green: 0.05, blue: 0.15)
    public static let paperWhite = Color(red: 1.00, green: 0.98, blue: 0.94)

    public static let bg = LinearGradient(
        colors: [hotPink, magenta, Color(red: 0.35, green: 0.10, blue: 0.55)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    public static let meter = LinearGradient(
        colors: [neonCyan, neonLime, neonYellow, hotPink],
        startPoint: .leading, endPoint: .trailing
    )
}

// MARK: - Decorations

/// A field of 3D sparkles rendered with Core Animation: each sparkle is a
/// `CAShapeLayer` star that tumbles in 3D (X/Y rotation under a perspective
/// `sublayerTransform`) while twinkling in and out. GPU-composited, so it's
/// cheap even with dozens of particles.
public struct SparkleField: View {
    let count: Int
    public init(count: Int) { self.count = count }
    public var body: some View {
        SparkleLayerView(count: count).allowsHitTesting(false)
    }
}

/// Build `count` animated 3D sparkle layers into `host`.
func buildSparkles(in host: CALayer, size: CGSize, count: Int) {
    guard size.width > 1, size.height > 1 else { return }
    host.sublayers?.forEach { $0.removeFromSuperlayer() }

    // Perspective so the X/Y tumble reads as depth.
    var perspective = CATransform3DIdentity
    perspective.m34 = -1.0 / 600.0
    host.sublayerTransform = perspective

    let now = CACurrentMediaTime()
    for _ in 0..<count {
        let s = CGFloat.random(in: 7...18)
        let cell = CAShapeLayer()
        cell.path = sparklePath(radius: s / 2)
        cell.fillColor = CGColor(gray: 1, alpha: 1)
        cell.bounds = CGRect(x: 0, y: 0, width: s, height: s)
        cell.position = CGPoint(x: .random(in: 0...size.width), y: .random(in: 0...size.height))
        cell.opacity = 0
        cell.shadowColor = CGColor(gray: 1, alpha: 1)
        cell.shadowRadius = 3
        cell.shadowOpacity = 0.8
        cell.shadowOffset = .zero

        let phase = -Double.random(in: 0...4)

        // 3D tumble: independent X and Y spins.
        let spinX = CABasicAnimation(keyPath: "transform.rotation.x")
        spinX.fromValue = 0; spinX.toValue = 2 * Double.pi
        spinX.duration = Double.random(in: 3.5...7)
        spinX.repeatCount = .infinity
        spinX.beginTime = now + phase
        cell.add(spinX, forKey: "spinX")

        let spinY = CABasicAnimation(keyPath: "transform.rotation.y")
        spinY.fromValue = 0; spinY.toValue = 2 * Double.pi
        spinY.duration = Double.random(in: 2.5...5.5)
        spinY.repeatCount = .infinity
        spinY.beginTime = now + phase
        cell.add(spinY, forKey: "spinY")

        // Twinkle.
        let tw = CABasicAnimation(keyPath: "opacity")
        tw.fromValue = 0.1; tw.toValue = CGFloat.random(in: 0.7...1.0)
        tw.duration = Double.random(in: 0.7...2.0)
        tw.autoreverses = true
        tw.repeatCount = .infinity
        tw.beginTime = now + phase
        cell.add(tw, forKey: "twinkle")

        // Gentle vertical drift.
        let drift = CABasicAnimation(keyPath: "position.y")
        drift.byValue = CGFloat.random(in: -14 ... -4)
        drift.duration = Double.random(in: 2.5...5)
        drift.autoreverses = true
        drift.repeatCount = .infinity
        drift.beginTime = now + phase
        cell.add(drift, forKey: "drift")

        host.addSublayer(cell)
    }
}

/// A crisp 4-point sparkle (concave diamond) path centered on its bounds.
func sparklePath(radius r: CGFloat) -> CGPath {
    let c = CGPoint(x: r, y: r)
    let inner = r * 0.34
    let path = CGMutablePath()
    path.move(to: CGPoint(x: c.x, y: c.y - r))                 // top
    path.addLine(to: CGPoint(x: c.x + inner, y: c.y - inner))
    path.addLine(to: CGPoint(x: c.x + r, y: c.y))             // right
    path.addLine(to: CGPoint(x: c.x + inner, y: c.y + inner))
    path.addLine(to: CGPoint(x: c.x, y: c.y + r))             // bottom
    path.addLine(to: CGPoint(x: c.x - inner, y: c.y + inner))
    path.addLine(to: CGPoint(x: c.x - r, y: c.y))             // left
    path.addLine(to: CGPoint(x: c.x - inner, y: c.y - inner))
    path.closeSubpath()
    return path
}

#if canImport(UIKit)
struct SparkleLayerView: UIViewRepresentable {
    let count: Int
    func makeUIView(context: Context) -> SparkleHostUIView { SparkleHostUIView(count: count) }
    func updateUIView(_ uiView: SparkleHostUIView, context: Context) {}
}

final class SparkleHostUIView: UIView {
    private let count: Int
    private var builtSize: CGSize = .zero
    init(count: Int) { self.count = count; super.init(frame: .zero); backgroundColor = .clear; isUserInteractionEnabled = false }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != builtSize {
            builtSize = bounds.size
            buildSparkles(in: layer, size: bounds.size, count: count)
        }
    }
}
#elseif canImport(AppKit)
struct SparkleLayerView: NSViewRepresentable {
    let count: Int
    func makeNSView(context: Context) -> SparkleHostNSView { SparkleHostNSView(count: count) }
    func updateNSView(_ nsView: SparkleHostNSView, context: Context) {}
}

final class SparkleHostNSView: NSView {
    private let count: Int
    private var builtSize: CGSize = .zero
    init(count: Int) { self.count = count; super.init(frame: .zero); wantsLayer = true }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layout() {
        super.layout()
        guard let layer else { return }
        if bounds.size != builtSize {
            builtSize = bounds.size
            buildSparkles(in: layer, size: bounds.size, count: count)
        }
    }
}
#endif

/// Chunky rounded panel with thick colored border and a hard offset shadow.
public struct GamePanel<Content: View>: View {
    var tint: Color
    let content: () -> Content
    public init(tint: Color = GameShow.neonCyan, @ViewBuilder content: @escaping () -> Content) {
        self.tint = tint
        self.content = content
    }
    public var body: some View {
        content()
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(GameShow.paperWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(tint, lineWidth: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(GameShow.inkBlack, lineWidth: 2).padding(2).opacity(0.15)
            )
            .compositingGroup()
            .shadow(color: GameShow.inkBlack.opacity(0.45), radius: 0, x: 4, y: 5)
    }
}

/// Big arcade action button with a hard sticker shadow it presses into.
public struct NeonButton: ButtonStyle {
    var fill: Color
    var text: Color
    public init(fill: Color, text: Color = GameShow.inkBlack) {
        self.fill = fill
        self.text = text
    }
    public func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(text)
            .lineLimit(1)                    // never wrap button text
            .minimumScaleFactor(0.7)         // shrink slightly to fit instead
            .fixedSize(horizontal: false, vertical: true)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LinearGradient(colors: [.white.opacity(0.35), .clear],
                                                 startPoint: .top, endPoint: .center))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(GameShow.inkBlack, lineWidth: 2.5)
            )
            .compositingGroup()
            .shadow(color: GameShow.inkBlack.opacity(0.55), radius: 0, x: 0, y: pressed ? 1 : 4)
            .offset(y: pressed ? 3 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: pressed)
    }
}

/// Theme-styled slider: capsule track, tinted fill, black-outlined thumb.
public struct ChunkySlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var tint: Color
    private let thumbSize: CGFloat = 20

    public init(value: Binding<Int>, range: ClosedRange<Int>, tint: Color) {
        self._value = value
        self.range = range
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { geo in
            let travel = max(geo.size.width - thumbSize, 1)
            let span = CGFloat(range.upperBound - range.lowerBound)
            let pct = CGFloat(value - range.lowerBound) / span
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(GameShow.inkBlack.opacity(0.10))
                    .overlay(Capsule().stroke(GameShow.inkBlack.opacity(0.30), lineWidth: 1.5))
                    .frame(height: 8)
                Capsule()
                    .fill(tint)
                    .overlay(Capsule().stroke(GameShow.inkBlack.opacity(0.30), lineWidth: 1.5))
                    .frame(width: thumbSize / 2 + travel * pct, height: 8)
                Circle()
                    .fill(.white)
                    .overlay(Circle().stroke(GameShow.inkBlack, lineWidth: 2))
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: GameShow.inkBlack.opacity(0.3), radius: 0, x: 0, y: 2)
                    .offset(x: travel * pct)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { g in
                    let p = min(max((g.location.x - thumbSize / 2) / travel, 0), 1)
                    value = range.lowerBound + Int((p * span).rounded())
                }
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: value)
        }
        .frame(height: 22)
    }
}
