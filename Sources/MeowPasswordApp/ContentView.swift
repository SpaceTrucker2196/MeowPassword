import SwiftUI
import AppKit

/// Resolve a bundled image by looking in `Bundle.main` first (the .app's
/// `Contents/Resources/`), then falling back to SwiftPM's module bundle for
/// `swift run` builds.
func loadBundledImage(_ name: String, ext: String) -> NSImage? {
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

    static let meter = LinearGradient(
        colors: [neonCyan, neonLime, neonYellow, hotPink],
        startPoint: .leading, endPoint: .trailing
    )
}

// MARK: - Reusable decorations

struct SparkleField: View {
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

/// Chunky rounded panel with thick colored border and a hard offset
/// "sticker" shadow, matching the flat black-outline banner art.
struct GamePanel<Content: View>: View {
    var tint: Color = GameShow.neonCyan
    let content: () -> Content

    var body: some View {
        content()
            .padding(12)
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
            .compositingGroup()
            .shadow(color: GameShow.inkBlack.opacity(0.45), radius: 0, x: 4, y: 5)
    }
}

/// Big arcade action button: hard sticker shadow that the button
/// physically presses down into.
struct NeonButton: ButtonStyle {
    var fill: Color
    var text: Color = GameShow.inkBlack

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        return configuration.label
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(text)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(fill)
                    .overlay(
                        // Top sheen for a little arcade-plastic depth.
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.white.opacity(0.35), .clear],
                                    startPoint: .top, endPoint: .center
                                )
                            )
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
/// Replaces the stock macOS slider, which fought the flat art style.
private struct ChunkySlider: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    var tint: Color

    private let thumbSize: CGFloat = 20

    var body: some View {
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
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        let p = min(max((g.location.x - thumbSize / 2) / travel, 0), 1)
                        value = range.lowerBound + Int((p * span).rounded())
                    }
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: value)
        }
        .frame(height: 22)
    }
}

// MARK: - Content

struct ContentView: View {
    @EnvironmentObject var model: GenerationModel
    @Environment(\.openWindow) private var openWindow
    @Namespace private var reveal

    var body: some View {
        ZStack {
            GameShow.bg.ignoresSafeArea()
            SparkleField(count: 60).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header

                    HStack(spacing: 12) {
                        Button {
                            model.generate()
                        } label: {
                            Label("GENERATE!", systemImage: "sparkles")
                        }
                        .keyboardShortcut("g", modifiers: [.command])
                        .buttonStyle(NeonButton(fill: GameShow.neonYellow))
                        .disabled(model.isBusy)
                        .opacity(model.isBusy ? 0.6 : 1)

                        Button {
                            openWindow(id: "meowgram")
                            NSApp.activate(ignoringOtherApps: true)
                        } label: {
                            Label("MEOWGRAM!", systemImage: "envelope.badge.fill")
                        }
                        .keyboardShortcut("m", modifiers: [.command, .shift])
                        .buttonStyle(NeonButton(fill: GameShow.neonLime))
                    }

                    if !model.bestPassword.isEmpty {
                        bestSection
                            .transition(.scale(scale: 0.92).combined(with: .opacity))
                    }
                    if !model.candidates.isEmpty {
                        candidatesSection
                            .transition(.opacity)
                    }

                    analyzePanel

                    controlsPanel

                    if let err = model.lastError {
                        errorBanner(err)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 0)
                .padding(.bottom, 18)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: model.bestPassword)
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
            // Cap the banner so the action buttons and winner stay above
            // the fold at the default window size.
            .frame(maxWidth: .infinity, maxHeight: 340)

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
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("RULES", jp: "ルール", tint: GameShow.hotPink)
                stepperRow(title: "NUMBERS",     jp: "すうじ",  value: $model.numbers, range: 1...10, tint: GameShow.hotPink)
                stepperRow(title: "SYMBOLS",     jp: "きごう",  value: $model.symbols, range: 1...10, tint: GameShow.neonCyan)
                stepperRow(title: "MAX LENGTH",  jp: "ながさ",  value: $model.maxLength, range: 15...50, tint: GameShow.neonLime)
            }
        }
    }

    private func stepperRow(title: String, jp: String, value: Binding<Int>, range: ClosedRange<Int>, tint: Color) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(GameShow.inkBlack)
                Text(jp)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(GameShow.inkBlack.opacity(0.55))
            }
            .frame(width: 86, alignment: .leading)

            ChunkySlider(value: value, range: range, tint: tint)

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
                HStack(spacing: 6) {
                    sectionLabel("WINNER!", jp: "ゆうしょう", tint: GameShow.hotPink)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(GameShow.neonYellow)
                        .shadow(color: GameShow.inkBlack, radius: 0, x: 1, y: 1)
                }

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
                    // Full-width gradient masked to the fill, so the leading
                    // edge color always reflects the score's position.
                    RoundedRectangle(cornerRadius: 6)
                        .fill(GameShow.meter)
                        .mask(
                            HStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .frame(width: geo.size.width * pct)
                                Spacer(minLength: 0)
                            }
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: pct)
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(GameShow.inkBlack, lineWidth: 1.5)
                }
            }
            .frame(height: 12)
        }
    }

    // MARK: candidates

    private var candidatesSection: some View {
        let topScore = model.candidates.map(\.score).max()
        return GamePanel(tint: GameShow.hotPink) {
            VStack(alignment: .leading, spacing: 2) {
                sectionLabel("CANDIDATES", jp: "こうほ", tint: GameShow.neonCyan)
                    .padding(.bottom, 4)
                ForEach(Array(model.candidates.enumerated()), id: \.element.id) { idx, c in
                    CandidateRow(
                        index: idx + 1,
                        candidate: c,
                        isChampion: c.score == topScore
                    )
                }
            }
        }
    }

    private struct CandidateRow: View {
        let index: Int
        let candidate: GenerationModel.Candidate
        let isChampion: Bool
        @State private var hovering = false

        var body: some View {
            HStack(spacing: 8) {
                Text("\(index)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(isChampion ? GameShow.inkBlack : .white)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(isChampion ? GameShow.neonYellow : GameShow.hotPink))
                    .overlay(Circle().stroke(GameShow.inkBlack, lineWidth: 1.5))

                Text(candidate.password)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(GameShow.inkBlack)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if isChampion {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(GameShow.neonYellow)
                        .shadow(color: GameShow.inkBlack, radius: 0, x: 1, y: 1)
                }

                Spacer()

                Text(String(format: "%.2f", candidate.score))
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
                    Clipboard.copy(candidate.password)
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(GameShow.inkBlack)
                        .padding(4)
                        .background(Circle().fill(GameShow.neonYellow))
                        .overlay(Circle().stroke(GameShow.inkBlack, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .opacity(hovering ? 1 : 0.55)
                .help("Copy")
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        hovering
                            ? GameShow.neonCyan.opacity(0.20)
                            : (isChampion ? GameShow.neonYellow.opacity(0.18) : .clear)
                    )
            )
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.12), value: hovering)
        }
    }

    // MARK: analyze

    private var analyzePanel: some View {
        GamePanel(tint: GameShow.neonLime) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("JUDGE!", jp: "しんさ", tint: GameShow.magenta)

                HStack(spacing: 8) {
                    TextField("", text: $model.analyzeInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(GameShow.inkBlack)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                        .overlay(alignment: .leading) {
                            // The .plain field style drops TextField's prompt,
                            // so draw the placeholder ourselves.
                            if model.analyzeInput.isEmpty {
                                Text("PASTE A PASSWORD…")
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(GameShow.inkBlack.opacity(0.35))
                                    .padding(.leading, 8)
                                    .allowsHitTesting(false)
                            }
                        }
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
                    .opacity(model.analyzeInput.isEmpty || model.isBusy ? 0.6 : 1)
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

    // MARK: error

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(GameShow.neonYellow)
            Text(message)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(GameShow.inkBlack, lineWidth: 2))
        )
        .compositingGroup()
        .shadow(color: GameShow.inkBlack.opacity(0.45), radius: 0, x: 4, y: 5)
    }
}
