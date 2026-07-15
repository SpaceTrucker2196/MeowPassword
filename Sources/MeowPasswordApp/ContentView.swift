import SwiftUI
import AppKit
import MeowUI

/// Resolve a bundled image by looking in `Bundle.main` first (the .app's
/// `Contents/Resources/`, used by both the XcodeGen app target and the
/// build_app.sh bundle), then falling back to SwiftPM's module bundle for
/// `swift run`. `Bundle.module` only exists when compiled by SwiftPM
/// (`SWIFT_PACKAGE`), so guard it — the XcodeGen macOS target has no such
/// accessor and would otherwise fail to compile.
func loadBundledImage(_ name: String, ext: String) -> NSImage? {
    if let url = Bundle.main.url(forResource: name, withExtension: ext),
       let img = NSImage(contentsOf: url) {
        return img
    }
    #if SWIFT_PACKAGE
    if let url = Bundle.module.url(forResource: name, withExtension: ext),
       let img = NSImage(contentsOf: url) {
        return img
    }
    #endif
    return nil
}


// MARK: - Content

struct ContentView: View {
    @EnvironmentObject var model: GenerationModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.theme) private var theme
    @Namespace private var reveal

    var body: some View {
        ZStack {
            ThemedBackground().ignoresSafeArea()
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
                        .buttonStyle(NeonButton(fill: theme.celebrate))
                        .disabled(model.isBusy)
                        .opacity(model.isBusy ? 0.6 : 1)

                        Button {
                            openWindow(id: "meowgram")
                            NSApp.activate(ignoringOtherApps: true)
                        } label: {
                            Label("MEOWGRAM!", systemImage: "envelope.badge.fill")
                        }
                        .keyboardShortcut("m", modifiers: [.command, .shift])
                        .buttonStyle(NeonButton(fill: theme.positive))
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
                    Rectangle().fill(theme.command)
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
                .background(Capsule().fill(theme.bind.opacity(0.75)))
                .padding(8)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: controls

    private var controlsPanel: some View {
        GamePanel(tint: theme.cool) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("RULES", jp: "ルール", tint: theme.command)
                stepperRow(title: "NUMBERS",     jp: "すうじ",  value: $model.numbers, range: 1...10, tint: theme.command)
                stepperRow(title: "SYMBOLS",     jp: "きごう",  value: $model.symbols, range: 1...10, tint: theme.cool)
                stepperRow(title: "MAX LENGTH",  jp: "ながさ",  value: $model.maxLength, range: 15...50, tint: theme.positive)
            }
        }
    }

    private func stepperRow(title: LocalizedStringKey, jp: String, value: Binding<Int>, range: ClosedRange<Int>, tint: Color) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(theme.bind)
                Text(jp)
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.bind.opacity(0.55))
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
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(theme.bind, lineWidth: 1.5))
                )
        }
    }

    private func sectionLabel(_ text: LocalizedStringKey, jp: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule().fill(tint)
                        .overlay(Capsule().stroke(theme.bind, lineWidth: 1.5))
                )
            Text(jp)
                .font(.system(size: 10, weight: .heavy, design: .rounded))
                .foregroundStyle(theme.bind.opacity(0.6))
            Spacer()
        }
    }

    // MARK: best

    private var bestSection: some View {
        GamePanel(tint: theme.celebrate) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    sectionLabel("WINNER!", jp: "ゆうしょう", tint: theme.command)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(theme.celebrate)
                        .shadow(color: theme.bind, radius: 0, x: 1, y: 1)
                }

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(theme.bind)
                    HStack {
                        Text(model.bestPassword)
                            .font(.system(size: 14, weight: .heavy, design: .monospaced))
                            .foregroundStyle(theme.celebrate)
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
                                .foregroundStyle(theme.bind)
                                .padding(6)
                                .background(Circle().fill(theme.celebrate))
                                .overlay(Circle().stroke(theme.bind, lineWidth: 1.5))
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
                    .foregroundStyle(theme.bind)
                Text("スコア")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.bind.opacity(0.55))
                Spacer()
                Text(String(format: "%.2f / 10.00", score))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(theme.bind)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.bind.opacity(0.1))
                    // Full-width gradient masked to the fill, so the leading
                    // edge color always reflects the score's position.
                    RoundedRectangle(cornerRadius: 6)
                        .fill(theme.meter)
                        .mask(
                            HStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .frame(width: geo.size.width * pct)
                                Spacer(minLength: 0)
                            }
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: pct)
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(theme.bind, lineWidth: 1.5)
                }
            }
            .frame(height: 12)
        }
    }

    // MARK: candidates

    private var candidatesSection: some View {
        let topScore = model.candidates.map(\.score).max()
        return GamePanel(tint: theme.command) {
            VStack(alignment: .leading, spacing: 2) {
                sectionLabel("CANDIDATES", jp: "こうほ", tint: theme.cool)
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
        @Environment(\.theme) private var theme
        @State private var hovering = false

        var body: some View {
            HStack(spacing: 8) {
                Text("\(index)")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(isChampion ? theme.bind : .white)
                    .frame(width: 18, height: 18)
                    .background(Circle().fill(isChampion ? theme.celebrate : theme.command))
                    .overlay(Circle().stroke(theme.bind, lineWidth: 1.5))

                Text(candidate.password)
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundStyle(theme.bind)
                    .textSelection(.enabled)
                    .lineLimit(1)
                    .truncationMode(.middle)

                if isChampion {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(theme.celebrate)
                        .shadow(color: theme.bind, radius: 0, x: 1, y: 1)
                }

                Spacer()

                Text(String(format: "%.2f", candidate.score))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(
                        Capsule().fill(theme.commandDeep)
                            .overlay(Capsule().stroke(theme.bind, lineWidth: 1.5))
                    )

                Button {
                    Clipboard.copy(candidate.password)
                } label: {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 10, weight: .black))
                        .foregroundStyle(theme.bind)
                        .padding(4)
                        .background(Circle().fill(theme.celebrate))
                        .overlay(Circle().stroke(theme.bind, lineWidth: 1.5))
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
                            ? theme.cool.opacity(0.20)
                            : (isChampion ? theme.celebrate.opacity(0.18) : .clear)
                    )
            )
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.12), value: hovering)
        }
    }

    // MARK: analyze

    private var analyzePanel: some View {
        GamePanel(tint: theme.positive) {
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("JUDGE!", jp: "しんさ", tint: theme.commandDeep)

                HStack(spacing: 8) {
                    TextField("", text: $model.analyzeInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(theme.bind)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(.white))
                        .overlay(alignment: .leading) {
                            // The .plain field style drops TextField's prompt,
                            // so draw the placeholder ourselves.
                            if model.analyzeInput.isEmpty {
                                Text("PASTE A PASSWORD…")
                                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                    .foregroundStyle(theme.bind.opacity(0.35))
                                    .padding(.leading, 8)
                                    .allowsHitTesting(false)
                            }
                        }
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.bind, lineWidth: 1.5))
                        .onSubmit { model.analyze() }

                    Button {
                        model.analyze()
                    } label: {
                        Label("ANALYZE!", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(NeonButton(fill: theme.command, text: .white))
                    .fixedSize()
                    .disabled(model.analyzeInput.isEmpty || model.isBusy)
                    .opacity(model.analyzeInput.isEmpty || model.isBusy ? 0.6 : 1)
                }

                if model.isAnalyzing {
                    EmbedGeneratingView(label: "JUDGING…")
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.bind, lineWidth: 1.5))
                } else if !model.analyzeResult.isEmpty {
                    ScrollView {
                        Text(model.analyzeResult)
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundStyle(theme.positive)
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 150)
                    .background(RoundedRectangle(cornerRadius: 8).fill(theme.bind))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.bind, lineWidth: 1.5))
                }
            }
        }
    }

    // MARK: error

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(theme.celebrate)
            Text(message)
                .font(.system(.footnote, design: .rounded).weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.red)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.bind, lineWidth: 2))
        )
        .compositingGroup()
        .shadow(color: theme.bind.opacity(0.45), radius: 0, x: 4, y: 5)
    }
}
