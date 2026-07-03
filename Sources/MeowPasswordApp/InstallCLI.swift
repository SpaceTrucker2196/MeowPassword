import Foundation
import AppKit

/// "Install Command-Line Tool…" feature.
///
/// Locates the bundled `meowpass` executable and drops it wherever the user
/// picks via NSSavePanel. Works under App Sandbox because the destination is
/// user-selected. Falls back to an `osascript` admin-auth prompt when the
/// direct copy fails (Direct/notarized builds only — sandboxed apps can't
/// escalate).
enum InstallCLI {

    /// Present the whole install flow. Meant to be called from the menu.
    @MainActor
    static func run() {
        guard let src = Bundle.main.url(forAuxiliaryExecutable: "meowpass"),
              FileManager.default.isReadableFile(atPath: src.path) else {
            alert(
                title: "meowpass not found",
                text: "The bundled command-line tool is missing from this build. Rebuild the app to include it."
            )
            return
        }

        let panel = NSSavePanel()
        panel.title = "Install meowpass"
        panel.message = "Choose a directory in your PATH. \n" +
                        "Common choices: /usr/local/bin, /opt/homebrew/bin, or ~/bin."
        panel.prompt = "Install"
        panel.nameFieldStringValue = "meowpass"
        panel.canCreateDirectories = true
        panel.directoryURL = defaultInstallDirectory()

        guard panel.runModal() == .OK, let dest = panel.url else { return }

        switch attemptCopy(from: src, to: dest) {
        case .success:
            alert(
                title: "Installed",
                text: "meowpass is now at:\n\(dest.path)\n\nMake sure that directory is on your $PATH."
            )
        case .permissionDenied:
            escalateAndCopy(from: src, to: dest)
        case .failed(let error):
            alert(
                title: "Install failed",
                text: error.localizedDescription
            )
        }
    }

    // MARK: - Copy strategies

    private enum CopyResult {
        case success
        case permissionDenied
        case failed(Error)
    }

    private static func attemptCopy(from src: URL, to dest: URL) -> CopyResult {
        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: src, to: dest)
            try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dest.path)
            return .success
        } catch let error as NSError {
            // POSIX EACCES == 13, EPERM == 1, EROFS == 30, EEXIST == 17
            if error.domain == NSCocoaErrorDomain,
               [NSFileWriteNoPermissionError, NSFileWriteUnknownError].contains(error.code) {
                return .permissionDenied
            }
            return .failed(error)
        }
    }

    /// Fallback for Direct/notarized builds: prompt the user for admin
    /// credentials via osascript and copy with sudo. This is blocked in
    /// the App Sandbox, so we detect that and inform the user.
    @MainActor
    private static func escalateAndCopy(from src: URL, to dest: URL) {
        if isSandboxed() {
            alert(
                title: "Permission denied",
                text: "This location requires administrator access, which the sandboxed Mac App Store build cannot request.\n\nPick a directory you own (like ~/bin) or install the CLI installer package instead."
            )
            return
        }

        let confirm = NSAlert()
        confirm.messageText = "Install to \(dest.path)?"
        confirm.informativeText = "This location requires administrator privileges. You'll be prompted for your password."
        confirm.addButton(withTitle: "Install with Admin")
        confirm.addButton(withTitle: "Cancel")
        guard confirm.runModal() == .alertFirstButtonReturn else { return }

        let escaped = { (path: String) in path.replacingOccurrences(of: "\"", with: "\\\"") }
        let srcPath = escaped(src.path)
        let dstPath = escaped(dest.path)
        let dirPath = escaped(dest.deletingLastPathComponent().path)

        let cmd = "mkdir -p \"\(dirPath)\" && cp \"\(srcPath)\" \"\(dstPath)\" && chmod 755 \"\(dstPath)\""
        let script = "do shell script \"\(cmd)\" with administrator privileges"

        var err: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&err)

        if let e = err {
            alert(
                title: "Install failed",
                text: (e["NSAppleScriptErrorMessage"] as? String) ?? "Unknown error."
            )
        } else {
            alert(
                title: "Installed",
                text: "meowpass is now at:\n\(dest.path)\n\nMake sure that directory is on your $PATH."
            )
        }
    }

    // MARK: - Helpers

    private static func defaultInstallDirectory() -> URL {
        let candidates = ["/usr/local/bin", "/opt/homebrew/bin"]
        for path in candidates {
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
                return URL(fileURLWithPath: path, isDirectory: true)
            }
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }

    private static func isSandboxed() -> Bool {
        // Environment marker set by macOS for any sandboxed process.
        return ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }

    @MainActor
    private static func alert(title: String, text: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = text
        alert.runModal()
    }
}
