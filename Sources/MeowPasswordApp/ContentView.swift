import SwiftUI
import AppKit

/// Resolve a bundled image by looking in `Bundle.main` first (the .app's
/// `Contents/Resources/`), then falling back to SwiftPM's module bundle for
/// `swift run` builds.
private func loadBundledImage(_ name: String, ext: String) -> NSImage? {
    if let url = Bundle.main.url(forResource: name, withExtension: ext),
       let img = NSImage(contentsOf: url) {
        return img
    }
    if let url = Bundle.module.url(forResource: name, withExtension: ext),
       let img = NSImage(contentsOf: url) {
        return img
    }
    return nil
}

// MARK: - Palette

enum GameShow {
    static let hotPink   = Color(red: 1.00, green: 0.24, blue: 0.63)
    static let magenta   = Color(red: 0.69, green: 0.13, blue: 0.56)
    static let neonYellow = Color(red: 1.00, green: 0.92, blue: 0.00)
    static let neonCyan  = Color(red: 0.00, green: 0.90, blue: 1.00)
    static let neonLime  = Color(red: 0.65, green: 1.00, blue: 0.20)
    static let inkBlack  = Color(red: 0.09, green: 0.05, blue: 0.15)
    static let paperWhite = Color(red: 1.00, green: 0.98, blue: 0.94)

    static let bg = LinearGradient(
        colors: [hotPink, magenta, Color(red: 0.35, green: 0.10, blue: 0.55)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Reusable decorations

private struct StarBurst: View {
    var color: Color = GameShow.neonYellow
    var points: Int = 16
    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let outer = min(size.width, size.height) / 2
            let inner = outer * 0.55
            var path = Path()
            for i in 0..<(points * 2) {
                let angle = (Double(i) / Double(points * 2)) * .pi * 2 - .pi / 2
                let radius = i.isMultiple(of: 2) ? outer : inner
                let pt = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * radius,
                    y: center.y + CGFloat(sin(angle)) * radius
                )
                if i == 0 { path.move(to: pt) } else { path.addLine(to: pt) }
            }
            path.closeSubpath()
            ctx.fill(path, with: .color(color))
        }
    }
}

private struct SparkleField: View {
    let count: Int
    var body: some View {
        Canvas { ctx, size in
            var rng = SystemRandomNumberGenerator()
            for _ in 0..<count {
                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                let r = CGFloat.random(in: 1...3, using: &rng)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                    with: .color(.white.opacity(0.7))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

/// Bold "game show" text — flat, no shadow.
private struct GameShowText: View {
    let text: String
    var size: CGFloat = 44
    var fill: Color = .white
    var stroke: Color = GameShow.inkBlack
    var strokeWidth: CGFloat = 3

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .black, design: .rounded))
            .foregroundStyle(fill)
    }
}

/// Chunky rounded panel with thick colored border and drop shadow.
private struct GamePanel<Content: View>: View {
    var tint: Color = GameShow.neonCyan
    let content: () -> Content

    var body: some View {
        content()
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(GameShow.paperWhite)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(tint, lineWidth: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(GameShow.inkBlack, lineWidth: 2)
                    .padding(2)
                    .opacity(0.15)
            )
    }
}

/// Big glowing action button.
private struct NeonButton: ButtonStyle {
    var fill: Color
    var text: Color = GameShow.inkBlack

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(text)
            .padding(.vertical, 9)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(GameShow.inkBlack, lineWidth: 2.5)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Content

struct ContentView: View {
    @EnvironmentObject var model: GenerationModel

    var body: some View {
        ZStack {
            GameShow.bg.ignoresSafeArea()
            SparkleField(count: 60).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    header

                    HStack(spacing: 10) {
                        Button {
                            model.generate()
                        } label: {
                            Label("GENERATE!", systemImage: "sparkles")
                        }
                        .keyboardShortcut("g", modifiers: [.command])
                        .buttonStyle(NeonButton(fill: GameShow.neonYellow))

                        Button {
                            model.generateAndCopy()
                        } label: {
                            Label("COPY!", systemImage: "doc.on.clipboard.fill")
                        }
                        .keyboardShortcut("c", modifiers: [.command, .shift])
                        .buttonStyle(NeonButton(fill: GameShow.neonLime))
                    }
                    .disabled(model.isBusy)

                    if !model.bestPassword.isEmpty { bestSection }
                    if !model.candidates.isEmpty  { candidatesSection }

                    analyzePanel

                    controlsPanel

                    if let err = model.lastError {
                        Text(err)
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(GameShow.inkBlack, lineWidth: 2))
                            )
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 0)
                .padding(.bottom, 14)
            }
        }
        .frame(minWidth: 500, minHeight: 640)
    }

    // MARK: header

    private var header: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let nsImage = loadBundledImage("banner", ext: "png") {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle().fill(GameShow.hotPink)
                }
            }
            .frame(maxWidth: .infinity)

            if model.isBusy {
                HStack(spacing: 6) {
                    ProgressView().controlSize(.small).tint(.white)
                    Text("READY…?")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(GameShow.inkBlack.opacity(0.75)))
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: controls

    private var controlsPanel: some View {
        GamePanel(tint: GameShow.neonCyan) {
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("RULES", jp: "ルール", tint: GameShow.hotPink)
                stepperRow(title: "NUMBERS",     jp: "すうじ",  value: $model.numbers, range: 1...10, tint: GameShow.hotPink)
                stepperRow(title: "SYMBOLS",     jp: "きごう",  value: $model.symbols, range: 1...10, tint: GameShow.neonCyan)
                stepperRow(title: "MAX LENGTH",  jp: "ながさ",  value: $model.maxLength, range: 15...50, tint: GameShow.neonLime)
            }
        }
    }

    private func stepperRow(title: String, jp: String, value: Binding<Int>, range: ClosedRange<Int>, tint: Color) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(GameShow.inkBlack)
                Text(jp)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(GameShow.inkBlack.opacity(0.55))
            }
            .frame(width: 86, alignment: .leading)

            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(tint)
            .controlSize(.small)

            Text("\(value.wrappedValue)")
                .font(.system(size: 15, weight: .black, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(width: 36, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6).fill(tint)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(GameShow.inkBlack, lineWidth: 1.5))
                )
        }
    }

    private func sectionLabel(_ text: String, jp: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill(tint)
                        .overlay(Capsule().stroke(GameShow.inkBlack, lineWidth: 1.5))
                )
            Text(jp)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(GameShow.inkBlack.opacity(0.6))
            Spacer()
        }
    }

    // MARK: best

    private var bestSection: some View {
        GamePanel(tint: GameShow.neonYellow) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("WINNER!", jp: "ゆうしょう", tint: GameShow.hotPink)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(GameShow.inkBlack)
                    HStack {
                        Text(model.bestPassword)
                            .font(.system(size: 14, weight: .heavy, design: .monospaced))
                            .foregroundStyle(GameShow.neonYellow)
                            .textSelection(.enabled)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                        Spacer()
                        Button {
                            model.copyBest()
                        } label: {
                            Image(systemName: "doc.on.clipboard.fill")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(GameShow.inkBlack)
                                .padding(6)
                                .background(Circle().fill(GameShow.neonYellow))
                                .overlay(Circle().stroke(GameShow.inkBlack, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .padding(.trailing, 6)
                        .help("Copy")
                    }
                }

                scoreMeter(model.bestScore)
            }
        }
    }

    private func scoreMeter(_ score: Double) -> some View {
        let pct = min(max(score / 10.0, 0), 1)
        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("SCORE")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(GameShow.inkBlack)
                Text("スコア")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(GameShow.inkBlack.opacity(0.55))
                Spacer()
                Text(String(format: "%.2f / 10.00", score))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(GameShow.inkBlack)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(GameShow.inkBlack.opacity(0.1))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [GameShow.neonCyan, GameShow.neonLime, GameShow.neonYellow, GameShow.hotPink],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * pct)
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(GameShow.inkBlack, lineWidth: 1.5)
                }
            }
            .frame(height: 12)
        }
    }

    // MARK: candidates

    private var candidatesSection: some View {
        GamePanel(tint: GameShow.hotPink) {
            VStack(alignment: .leading, spacing: 5) {
                sectionLabel("CANDIDATES", jp: "こうほ", tint: GameShow.neonCyan)
                ForEach(Array(model.candidates.enumerated()), id: \.element.id) { idx, c in
                    HStack(spacing: 6) {
                        Text("\(idx + 1)")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(GameShow.hotPink))
                            .overlay(Circle().stroke(GameShow.inkBlack, lineWidth: 1.5))

                        Text(c.password)
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundStyle(GameShow.inkBlack)
                            .textSelection(.enabled)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        Text(String(format: "%.2f", c.score))
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(
                                Capsule().fill(GameShow.magenta)
                                    .overlay(Capsule().stroke(GameShow.inkBlack, lineWidth: 1.5))
                            )

                        Button {
                            Clipboard.copy(c.password)
                        } label: {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(GameShow.inkBlack)
                                .padding(4)
                                .background(Circle().fill(GameShow.neonYellow))
                                .overlay(Circle().stroke(GameShow.inkBlack, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: analyze

    private var analyzePanel: some View {
        GamePanel(tint: GameShow.neonLime) {
            VStack(alignment: .leading, spacing: 6) {
                sectionLabel("JUDGE!", jp: "しんさ", tint: GameShow.magenta)

                HStack(spacing: 6) {
                    TextField("PASTE STRING…", text: $model.analyzeInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(GameShow.inkBlack, lineWidth: 1.5))
                        .onSubmit { model.analyze() }

                    Button {
                        model.analyze()
                    } label: {
                        Label("ANALYZE!", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(NeonButton(fill: GameShow.hotPink, text: .white))
                    .fixedSize()
                    .disabled(model.analyzeInput.isEmpty || model.isBusy)
                }

                if !model.analyzeResult.isEmpty {
                    ScrollView {
                        Text(model.analyzeResult)
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(GameShow.neonLime)
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                    .background(RoundedRectangle(cornerRadius: 8).fill(GameShow.inkBlack))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(GameShow.inkBlack, lineWidth: 1.5))
                }
            }
        }
    }
}
