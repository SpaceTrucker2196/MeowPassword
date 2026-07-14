import AppKit
import MeowPassCore

/// Handler for the macOS Services menu. Selectors below are referenced by
/// name from Info.plist's NSServices entries.
final class ServicesBridge: NSObject {

    /// Right-click any text field with something selected → Services →
    /// "Insert MeowPassword". Replaces the selection with a fresh password.
    @objc func insertMeowPassword(_ pboard: NSPasteboard, userData: String?, error errorOut: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let best = MeowPass.best(config: PasswordConfig(numNumbers: 3, numSymbols: 2, maxLength: 25), count: 5)
        pboard.clearContents()
        pboard.setString(best.password, forType: .string)
    }

    /// Select any string → Services → "Analyze with MeowPassword".
    /// Replaces the selection with the full catified analysis in place.
    @objc func analyzeWithMeowPassword(_ pboard: NSPasteboard, userData: String?, error errorOut: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let input = pboard.string(forType: .string), !input.isEmpty else {
            errorOut.pointee = String(localized: "MeowPassword: no text selected") as NSString
            return
        }
        let result = MeowPass.analyze(input)
        pboard.clearContents()
        pboard.setString(result.analysis + "\n\n" + result.verdict, forType: .string)
    }
}
