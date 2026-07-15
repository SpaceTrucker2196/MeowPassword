import SwiftUI
import UIKit
import MeowUI
import MeowPassCore

@MainActor
final class GenerateModel: ObservableObject {
    @Published var numbers = 3
    @Published var symbols = 2
    @Published var maxLength = 25
    @Published var candidates: [Candidate] = []
    @Published var best: Candidate?
    @Published var analyzeInput = ""
    @Published var analyzeResult = ""
    @Published var isBusy = false
    @Published var isAnalyzing = false

    private func config() -> PasswordConfig {
        PasswordConfig(numNumbers: numbers, numSymbols: symbols, maxLength: maxLength)
    }

    func generate(copy: Bool = false) {
        isBusy = true
        let cfg = config()
        Task {
            let cands = await Task.detached { MeowPass.generate(config: cfg, count: 5) }.value
            self.candidates = cands
            self.best = cands.max(by: { $0.score < $1.score })
            if copy, let b = self.best { UIPasteboard.general.string = b.password }
            self.isBusy = false
        }
    }

    func analyze() {
        guard !analyzeInput.isEmpty else { return }
        let input = analyzeInput
        isAnalyzing = true
        analyzeResult = ""
        Task {
            async let minShow: Void = Task.sleep(nanoseconds: 1_100_000_000)  // let the animation land
            let r = await Task.detached { MeowPass.analyze(input) }.value
            try? await minShow
            // Keep the whimsical analysis block in English; localize the verdict by score.
            let verdict: String
            switch r.score {
            case ..<3.0: verdict = String(localized: "Hiss! A kitten could paw this one open! Try a meowpass-generated password instead!")
            case ..<5.0: verdict = String(localized: "Meow... this string is a bit too easy for a clever cat to guess.")
            case ..<7.0: verdict = String(localized: "Not bad, hooman! This string has decent whisker-resistance.")
            default: verdict = String(localized: "Purrfect! This string is fur-midably complex. Even the cleverest cats can't crack it!")
            }
            self.analyzeResult = r.analysis + "\n\n" + verdict
            self.isAnalyzing = false
        }
    }
}

struct GenerateView: View {
    @StateObject private var model = GenerateModel()
    var onMeowGram: () -> Void = {}
    /// On iPad the MeowGram system sits in its own column, so the button that
    /// opens it (and the first-launch tour) are redundant here.
    var showsMeowGramButton = true
    var autoTour = true

    @AppStorage("meow.tut.generate.v1") private var seenTour = false
    @State private var showTour = false
    @Environment(\.theme) private var theme

    private var tourSteps: [CoachStep] {
        [
            CoachStep(title: "WELCOME!",
                      text: "MeowPassword makes passwords that are strong, easy to read aloud, and — with MeowGram — hideable inside cat photos."),
            CoachStep(anchor: "gen.generate", title: "GENERATE!",
                      text: "Conjures five strong passwords and crowns the highest-scoring winner. Tap the clipboard to copy it."),
            CoachStep(anchor: "gen.meowgram", title: "MEOWGRAM!",
                      text: "Opens the cat-mail studio — hide a secret message inside an ordinary-looking cat picture, or decode one you were sent."),
            CoachStep(anchor: "gen.judge", title: "JUDGE!",
                      text: "Paste any password to score its strength from 0 to 10, with a verdict."),
            CoachStep(anchor: "gen.rules", title: "RULES",
                      text: "Dial in how many numbers and symbols to mix in, and the maximum length."),
        ]
    }

    var body: some View {
        ZStack {
            ThemedBackground().ignoresSafeArea()
            SparkleField(count: 50).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    hero

                    HStack(spacing: 12) {
                        Button { model.generate() } label: {
                            Label("GENERATE!", systemImage: "sparkles")
                        }
                        .buttonStyle(NeonButton(fill: theme.celebrate))
                        .disabled(model.isBusy)
                        .opacity(model.isBusy ? 0.6 : 1)
                        .coachAnchor("gen.generate")

                        if showsMeowGramButton {
                            Button { onMeowGram() } label: {
                                Label("MEOWGRAM!", systemImage: "envelope.badge.fill")
                            }
                            .buttonStyle(NeonButton(fill: theme.positive))
                            .coachAnchor("gen.meowgram")
                        }
                    }

                    if let best = model.best { winner(best) }
                    if !model.candidates.isEmpty { candidatesPanel }
                    analyzePanel.coachAnchor("gen.judge")
                    rulesPanel.coachAnchor("gen.rules")
                }
                .padding(16)
            }
        }
        .overlay(alignment: .topTrailing) { helpButton }
        .coachTour(tourSteps, isActive: $showTour)
        .onAppear {
            if autoTour, !seenTour { showTour = true }
            #if DEBUG
            // QA/screenshots: `-demoGenerate` fills the screen with a result.
            if ProcessInfo.processInfo.arguments.contains("-demoGenerate") { model.generate() }
            #endif
        }
        .onChange(of: showTour) { _, active in if !active { seenTour = true } }
    }

    private var helpButton: some View {
        Button { showTour = true } label: {
            Image(systemName: "questionmark")
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(theme.bind)
                .frame(width: 34, height: 34)
                .background(Circle().fill(theme.surface))
                .overlay(Circle().stroke(theme.bind, lineWidth: 2))
        }
        .padding(.trailing, 16).padding(.top, 8)
    }

    private var hero: some View {
        Image("banner")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: 260)
    }

    private func winner(_ best: Candidate) -> some View {
        GamePanel(tint: theme.celebrate) {
            VStack(alignment: .leading, spacing: 8) {
                label("WINNER!", tint: theme.command)
                HStack {
                    Text(best.password)
                        .font(.system(size: 15, weight: .heavy, design: .monospaced))
                        .foregroundStyle(theme.celebrate)
                        .textSelection(.enabled)
                        .lineLimit(1).truncationMode(.middle)
                        .padding(10)
                    Spacer()
                    Button { UIPasteboard.general.string = best.password } label: {
                        Image(systemName: "doc.on.clipboard.fill")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(theme.bind)
                            .padding(7)
                            .background(Circle().fill(theme.celebrate))
                            .overlay(Circle().stroke(theme.bind, lineWidth: 1.5))
                    }
                    .padding(.trailing, 6)
                }
                .background(RoundedRectangle(cornerRadius: 10).fill(theme.bind))
                scoreMeter(best.score)
            }
        }
    }

    private func scoreMeter(_ score: Double) -> some View {
        let pct = min(max(score / 10.0, 0), 1)
        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("SCORE").font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(theme.bind)
                Spacer()
                Text(String(format: "%.2f / 10.00", score))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .monospacedDigit().foregroundStyle(theme.bind)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(theme.bind.opacity(0.1))
                    RoundedRectangle(cornerRadius: 6).fill(theme.meter)
                        .mask(HStack { RoundedRectangle(cornerRadius: 6)
                            .frame(width: geo.size.width * pct); Spacer(minLength: 0) })
                    RoundedRectangle(cornerRadius: 6).stroke(theme.bind, lineWidth: 1.5)
                }
            }
            .frame(height: 12)
        }
    }

    private var candidatesPanel: some View {
        GamePanel(tint: theme.command) {
            VStack(alignment: .leading, spacing: 4) {
                label("CANDIDATES", tint: theme.cool)
                ForEach(model.candidates) { c in
                    HStack {
                        Text(c.password)
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundStyle(theme.bind)
                            .lineLimit(1).truncationMode(.middle)
                        Spacer()
                        Text(String(format: "%.2f", c.score))
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .monospacedDigit().foregroundStyle(theme.textOnCommand)
                            .padding(.horizontal, 6).padding(.vertical, 1)
                            .background(Capsule().fill(theme.commandDeep))
                        Button { UIPasteboard.general.string = c.password } label: {
                            Image(systemName: "doc.on.clipboard")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(theme.bind)
                        }
                    }
                    .padding(.vertical, 3)
                }
            }
        }
    }

    private var analyzePanel: some View {
        GamePanel(tint: theme.positive) {
            VStack(alignment: .leading, spacing: 8) {
                label("JUDGE!", tint: theme.commandDeep)
                HStack {
                    TextField("Paste a password…", text: $model.analyzeInput)
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundStyle(theme.bind)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(theme.surface))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.bind, lineWidth: 1.5))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    Button { model.analyze() } label: { Label("GO", systemImage: "magnifyingglass") }
                        .buttonStyle(NeonButton(fill: theme.command, text: theme.textOnCommand))
                        .fixedSize()
                        .disabled(model.analyzeInput.isEmpty)
                }
                if model.isAnalyzing {
                    EmbedGeneratingView(label: "JUDGING…")
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if !model.analyzeResult.isEmpty {
                    Text(model.analyzeResult)
                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                        .foregroundStyle(theme.positive)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 8).fill(theme.bind))
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var rulesPanel: some View {
        GamePanel(tint: theme.cool) {
            VStack(alignment: .leading, spacing: 8) {
                label("RULES", tint: theme.command)
                rule("NUMBERS", value: $model.numbers, range: 1...10, tint: theme.command)
                rule("SYMBOLS", value: $model.symbols, range: 1...10, tint: theme.cool)
                rule("MAX LENGTH", value: $model.maxLength, range: 15...50, tint: theme.positive)
            }
        }
    }

    private func rule(_ title: LocalizedStringKey, value: Binding<Int>, range: ClosedRange<Int>, tint: Color) -> some View {
        HStack(spacing: 10) {
            Text(title).font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(theme.bind).frame(width: 96, alignment: .leading)
            ChunkySlider(value: value, range: range, tint: tint)
            Text("\(value.wrappedValue)")
                .font(.system(size: 14, weight: .black, design: .rounded)).monospacedDigit()
                .foregroundStyle(theme.textOnCommand).frame(width: 34, height: 24)
                .background(RoundedRectangle(cornerRadius: 6).fill(tint))
        }
    }

    private func label(_ text: LocalizedStringKey, tint: Color) -> some View {
        HStack {
            Text(text).font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(theme.textOnCommand).padding(.horizontal, 8).padding(.vertical, 2)
                .background(Capsule().fill(tint).overlay(Capsule().stroke(theme.bind, lineWidth: 1.5)))
            Spacer()
        }
    }
}
