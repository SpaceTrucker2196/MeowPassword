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
    init(count: Int) {
        self.count = count
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        // Core Animation removes running animations when the layer leaves the
        // window (a full-screen cover) or the app backgrounds — re-add them on
        // return so the sparkles never freeze.
        NotificationCenter.default.addObserver(self, selector: #selector(rebuild),
            name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.size != builtSize {
            builtSize = bounds.size
            buildSparkles(in: layer, size: bounds.size, count: count)
        }
    }
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { rebuild() }
    }
    @objc private func rebuild() {
        guard bounds.width > 1, bounds.height > 1 else { return }
        builtSize = bounds.size
        buildSparkles(in: layer, size: bounds.size, count: count)
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
    init(count: Int) {
        self.count = count
        super.init(frame: .zero)
        wantsLayer = true
        NotificationCenter.default.addObserver(self, selector: #selector(rebuild),
            name: NSApplication.didBecomeActiveNotification, object: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func layout() {
        super.layout()
        guard let layer else { return }
        if bounds.size != builtSize {
            builtSize = bounds.size
            buildSparkles(in: layer, size: bounds.size, count: count)
        }
    }
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        rebuild()
    }
    @objc private func rebuild() {
        guard let layer, bounds.width > 1, bounds.height > 1, window != nil else { return }
        builtSize = bounds.size
        buildSparkles(in: layer, size: bounds.size, count: count)
    }
}
#endif

/// Chunky rounded panel with thick colored border and a hard offset shadow.
/// A nil `tint` uses the theme's cool accent.
public struct GamePanel<Content: View>: View {
    var tint: Color?
    let content: () -> Content
    @Environment(\.theme) private var theme
    public init(tint: Color? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.tint = tint
        self.content = content
    }
    public var body: some View {
        content()
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(tint ?? theme.cool, lineWidth: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(theme.bind, lineWidth: 2).padding(2).opacity(0.15)
            )
            .compositingGroup()
            .shadow(color: theme.bind.opacity(0.45), radius: 0, x: 4, y: 5)
    }
}

/// Big arcade action button with a hard sticker shadow it presses into.
/// A nil `text` uses the theme's bind (ink) color.
public struct NeonButton: ButtonStyle {
    var fill: Color
    var text: Color?
    public init(fill: Color, text: Color? = nil) {
        self.fill = fill
        self.text = text
    }
    public func makeBody(configuration: Configuration) -> some View {
        // Environment isn't reliably refreshed on a ButtonStyle struct itself
        // (it's not a View) — read it in a nested View instead.
        Styled(configuration: configuration, fill: fill, text: text)
    }

    private struct Styled: View {
        let configuration: Configuration
        let fill: Color
        let text: Color?
        @Environment(\.theme) private var theme

        var body: some View {
            let pressed = configuration.isPressed
            configuration.label
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(text ?? theme.bind)
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
                        .stroke(theme.bind, lineWidth: 2.5)
                )
                .compositingGroup()
                .shadow(color: theme.bind.opacity(0.55), radius: 0, x: 0, y: pressed ? 1 : 4)
                .offset(y: pressed ? 3 : 0)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: pressed)
        }
    }
}

/// Full-frame "generating" animation shown while a MeowGram is being embedded:
/// a spinning sunburst pinwheel, a pulsing ink medallion with a cat, orbiting
/// sparkles, and a broadcast-style chyron. Fills whatever frame it's given.
public struct EmbedGeneratingView: View {
    var label: String
    @Environment(\.theme) private var theme
    public init(label: String = "EMBEDDING…") { self.label = label }

    private var wheel: AngularGradient {
        let colors = [theme.celebrate, theme.command, theme.cool, theme.commandDeep]
        let segments = 16
        var stops: [Gradient.Stop] = []
        for i in 0..<segments {
            let c = colors[i % colors.count]
            stops.append(.init(color: c, location: Double(i) / Double(segments)))
            stops.append(.init(color: c, location: Double(i + 1) / Double(segments) - 0.0001))
        }
        return AngularGradient(gradient: Gradient(stops: stops), center: .center)
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 1.0 + 0.08 * sin(t * 3.2)
            GeometryReader { geo in
                let side = max(geo.size.width, geo.size.height) * 1.6
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let orbit = min(geo.size.width, geo.size.height) * 0.32
                ZStack {
                    theme.bind.opacity(0.06)

                    // Spinning sunburst pinwheel.
                    Circle()
                        .fill(wheel)
                        .frame(width: side, height: side)
                        .rotationEffect(.degrees(t * 45))
                        .opacity(0.9)
                        .position(center)
                        .mask(Circle().frame(width: side, height: side).position(center))

                    // Soft ink vignette so the medallion pops.
                    RadialGradient(colors: [.clear, theme.bind.opacity(0.35)],
                                   center: .center, startRadius: orbit * 0.6, endRadius: side * 0.5)
                        .position(center)

                    // Orbiting sparkles.
                    ForEach(0..<7, id: \.self) { i in
                        let a = t * 1.6 + Double(i) * (.pi * 2 / 7)
                        Image(systemName: "sparkle")
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.white)
                            .shadow(color: theme.bind, radius: 0, x: 1, y: 1)
                            .opacity(0.55 + 0.45 * sin(t * 4 + Double(i)))
                            .position(x: center.x + CGFloat(cos(a)) * orbit,
                                      y: center.y + CGFloat(sin(a)) * orbit)
                    }

                    // Pulsing medallion.
                    ZStack {
                        Circle().fill(theme.bind)
                        Circle().stroke(theme.celebrate, lineWidth: 4)
                            .padding(5)
                        Image(systemName: "cat.fill")
                            .font(.system(size: 34, weight: .black))
                            .foregroundStyle(theme.celebrate)
                            .rotationEffect(.degrees(sin(t * 2) * 12))
                    }
                    .frame(width: orbit * 1.15, height: orbit * 1.15)
                    .scaleEffect(pulse)
                    .position(center)

                    // Chyron.
                    VStack {
                        Spacer()
                        Text(LocalizedStringKey(label))
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(theme.bind)
                            .padding(.horizontal, 12).padding(.vertical, 5)
                            .background(Capsule().fill(theme.celebrate)
                                .overlay(Capsule().stroke(theme.bind, lineWidth: 2)))
                            .padding(.bottom, 10)
                    }
                }
            }
        }
        .clipped()
    }
}

/// Full-frame "decoding" animation: katakana digital rain in the broadcast
/// neon palette with a sweeping read-head scan line and a chyron. Meant to be
/// laid OVER the MeowGram being decoded (semi-opaque ink) so it reads as the
/// image itself being decoded. Fills whatever frame it's given.
public struct MatrixDecodeView: View {
    var label: String
    @Environment(\.theme) private var theme
    public init(label: String = "DECODING…") { self.label = label }

    // Halfwidth katakana + digits + symbols — echoes the ミャオ broadcast type.
    private static let glyphs = Array("ﾊﾐﾋｰｳｼﾅﾓﾆｻﾜﾂｵﾘｱﾎﾃﾏｹﾒｴｶｷﾑﾕﾗｾﾈｽﾀﾇﾍ0123456789=+-*<>#%&$@")

    public var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                // Semi-opaque so the cat ghosts through — "decoding the image".
                theme.bind.opacity(0.88)

                Canvas { ctx, size in
                    let colW: CGFloat = 16, rowH: CGFloat = 18, tail = 10
                    let cols = max(1, Int(size.width / colW))
                    let rows = max(1, Int(size.height / rowH))
                    let wrap = Double(rows + tail + 2)
                    for c in 0..<cols {
                        let speed = 7.0 + Double((c * 37) % 9)               // rows/sec, per column
                        let phase = Double((c * 53) % 100) / 100.0 * wrap
                        let head = (t * speed + phase).truncatingRemainder(dividingBy: wrap)
                        for k in 0...tail {
                            let r = Int(head) - k
                            if r < 0 || r >= rows { continue }
                            let bright = 1.0 - Double(k) / Double(tail)
                            let gi = abs(Int(t * 8 + Double(c) * 3) + r * 13) % Self.glyphs.count
                            let base = (k == 0) ? Color.white : (c % 3 == 0 ? theme.cool : theme.positive)
                            ctx.draw(
                                Text(String(Self.glyphs[gi]))
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(base.opacity(bright)),
                                at: CGPoint(x: CGFloat(c) * colW + colW / 2,
                                            y: CGFloat(r) * rowH + rowH / 2))
                        }
                    }
                }

                // Sweeping read-head scan line.
                GeometryReader { geo in
                    let y = (sin(t * 1.5) * 0.5 + 0.5) * geo.size.height
                    Rectangle()
                        .fill(LinearGradient(colors: [.clear, theme.cool.opacity(0.85), .clear],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(height: 24)
                        .position(x: geo.size.width / 2, y: y)
                }

                // Chyron.
                VStack {
                    Spacer()
                    Text(LocalizedStringKey(label))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(theme.bind)
                        .padding(.horizontal, 12).padding(.vertical, 5)
                        .background(Capsule().fill(theme.positive)
                            .overlay(Capsule().stroke(theme.bind, lineWidth: 2)))
                        .padding(.bottom, 10)
                }
            }
        }
        .clipped()
    }
}

/// Theme-styled slider: capsule track, tinted fill, black-outlined thumb.
public struct ChunkySlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var tint: Color
    @Environment(\.theme) private var theme
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
                    .fill(theme.bind.opacity(0.10))
                    .overlay(Capsule().stroke(theme.bind.opacity(0.30), lineWidth: 1.5))
                    .frame(height: 8)
                Capsule()
                    .fill(tint)
                    .overlay(Capsule().stroke(theme.bind.opacity(0.30), lineWidth: 1.5))
                    .frame(width: thumbSize / 2 + travel * pct, height: 8)
                Circle()
                    .fill(.white)
                    .overlay(Circle().stroke(theme.bind, lineWidth: 2))
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: theme.bind.opacity(0.3), radius: 0, x: 0, y: 2)
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

// MARK: - Coach marks (first-launch guided tours)

/// One stop on a guided tour. `anchor` names a control tagged with
/// `.coachAnchor(_:)`; a nil anchor is a centered intro card.
public struct CoachStep: Identifiable {
    public let id = UUID()
    public var anchorID: String?
    public var title: String
    public var text: String
    public init(anchor: String? = nil, title: String, text: String) {
        self.anchorID = anchor
        self.title = title
        self.text = text
    }
}

/// Collects the on-screen bounds of every control tagged with `.coachAnchor`.
public struct CoachAnchorKey: PreferenceKey {
    public static let defaultValue: [String: Anchor<CGRect>] = [:]
    public static func reduce(value: inout [String: Anchor<CGRect>],
                              nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { _, new in new }
    }
}

public extension View {
    /// Tag a control so a `coachTour` step can spotlight it by `id`.
    func coachAnchor(_ id: String) -> some View {
        anchorPreference(key: CoachAnchorKey.self, value: .bounds) { [id: $0] }
    }

    /// Attach a guided tour to a screen root. When `isActive` is true it dims
    /// the screen, spotlights each step's anchored control, and shows a caption
    /// card. Flip `isActive` to false to dismiss (do this once and persist it
    /// with @AppStorage for a real first-launch tutorial).
    func coachTour(_ steps: [CoachStep], isActive: Binding<Bool>) -> some View {
        overlayPreferenceValue(CoachAnchorKey.self) { anchors in
            GeometryReader { proxy in
                if isActive.wrappedValue && !steps.isEmpty {
                    CoachOverlay(steps: steps, anchors: anchors, proxy: proxy, isActive: isActive)
                }
            }
        }
    }

}

struct CoachOverlay: View {
    let steps: [CoachStep]
    let anchors: [String: Anchor<CGRect>]
    let proxy: GeometryProxy
    @Binding var isActive: Bool
    @Environment(\.theme) private var theme
    @State private var index: Int = {
        #if DEBUG
        // QA: jump straight to a step to verify spotlight alignment, e.g.
        // `xcrun simctl launch <sim> <bid> -coachStart 3`.
        let a = ProcessInfo.processInfo.arguments
        if let i = a.firstIndex(of: "-coachStart"), i + 1 < a.count, let n = Int(a[i + 1]) { return n }
        #endif
        return 0
    }()

    private var step: CoachStep { steps[min(index, steps.count - 1)] }
    private var targetRect: CGRect? {
        step.anchorID.flatMap { anchors[$0] }.map { proxy[$0].insetBy(dx: -7, dy: -7) }
    }
    private var last: Bool { index >= steps.count - 1 }
    private func finish() { withAnimation { isActive = false } }

    var body: some View {
        let rect = targetRect
        // Place the caption opposite the target so it never covers it.
        let cardAtTop = (rect?.midY ?? proxy.size.height / 2) > proxy.size.height / 2
        ZStack {
            Rectangle()
                .fill(Color.black.opacity(0.74))
                .mask {
                    ZStack {
                        Rectangle().fill(.white)
                        if let r = rect {
                            RoundedRectangle(cornerRadius: 14)
                                .frame(width: r.width, height: r.height)
                                .position(x: r.midX, y: r.midY)
                                .blendMode(.destinationOut)   // punch the spotlight hole
                        }
                    }
                    .compositingGroup()
                }
                .contentShape(Rectangle())
                .onTapGesture { advance() }

            if let r = rect {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.celebrate, lineWidth: 3)
                    .frame(width: r.width, height: r.height)
                    .position(x: r.midX, y: r.midY)
                    .allowsHitTesting(false)
            }

            VStack {
                if rect == nil { Spacer() }        // intro: center
                else if cardAtTop { } else { Spacer() }
                card
                if rect == nil { Spacer() }
                else if cardAtTop { Spacer() } else { }
            }
            .padding(18)
        }
        // NB: no .ignoresSafeArea() — the spotlight is positioned in the
        // preference GeometryReader's coordinate space, so the overlay must
        // share it or the hole/ring drift by the safe-area inset.
        .transition(.opacity)
    }

    private func advance() {
        if last { finish() } else { withAnimation { index += 1 } }
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStringKey(step.title))
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 3)
                    .background(Capsule().fill(theme.command)
                        .overlay(Capsule().stroke(theme.bind, lineWidth: 1.5)))
                Spacer()
                Text("\(index + 1)/\(steps.count)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(theme.bind.opacity(0.55))
            }
            Text(LocalizedStringKey(step.text))
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.bind)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Button { finish() } label: {
                    Text("SKIP")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(theme.bind.opacity(0.6))
                }
                Spacer()
                Button { advance() } label: {
                    Text(last ? LocalizedStringKey("GOT IT!") : LocalizedStringKey("NEXT"))
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Capsule().fill(last ? theme.positive : theme.command)
                            .overlay(Capsule().stroke(theme.bind, lineWidth: 2)))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: 340)
        .background(RoundedRectangle(cornerRadius: 16).fill(theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.bind, lineWidth: 2.5))
            .shadow(color: theme.bind.opacity(0.5), radius: 0, x: 0, y: 5))
    }
}
