import AppKit

/// Handler for the macOS Services menu. Selectors below are referenced by
/// name from Info.plist's NSServices entries.
final class ServicesBridge: NSObject {

    /// Right-click any text field with something selected → Services →
    /// "Insert MeowPassword". Replaces the selection with a fresh password.
    @objc func insertMeowPassword(_ pboard: NSPasteboard, userData: String?, error errorOut: AutoreleasingUnsafeMutablePointer<NSString?>) {
        do {
            let result = try MeowRunner.generate(numbers: 3, symbols: 2, maxLength: 25)
            pboard.clearContents()
            pboard.setString(result.best, forType: .string)
        } catch {
            errorOut.pointee = "MeowPassword: \(error.localizedDescription)" as NSString
        }
    }

    /// Select any string → Services → "Analyze with MeowPassword".
    /// Runs `meowpass --analyze` on the selection and replaces it with the
    /// full catified analysis so the user can read it in place.
    @objc func analyzeWithMeowPassword(_ pboard: NSPasteboard, userData: String?, error errorOut: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let input = pboard.string(forType: .string), !input.isEmpty else {
            errorOut.pointee = "MeowPassword: no text selected" as NSString
            return
        }
        do {
            let output = try MeowRunner.analyze(input)
            pboard.clearContents()
            pboard.setString(output, forType: .string)
        } catch {
            errorOut.pointee = "MeowPassword: \(error.localizedDescription)" as NSString
        }
    }
}
