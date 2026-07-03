# Wiring MeowPassword into macOS Password AutoFill

The SwiftPM app in this repo covers menu-bar, Services menu, URL scheme,
and Shortcuts / Spotlight (App Intents). The one integration that
**requires Xcode** — because it needs an app-extension target, signing,
entitlements, and an App Group — is Apple's **AutoFill Credential Provider**.
When wired up, MeowPassword becomes a first-class option in the system's
"Passwords" preference pane and in Safari's "Suggest Strong Password".

## What you're building

An **ASCredentialProviderExtension**. Selected in
System Settings → Passwords → Password Options → AutoFill Passwords From,
your extension is invoked whenever Safari or a native app asks for a new
password.

## One-time Xcode setup

1. **Open the SwiftPM package in Xcode** (`File → Open…` → the repo).
   Xcode 15+ builds SwiftPM executable targets as first-class app targets.
   If you prefer a native Xcode project, `File → New → Project → macOS App`,
   then drag `Sources/MeowPasswordApp/` in.

2. **Add a new target**: `File → New → Target → macOS → Credential Provider Extension`.
   Name it `MeowAutoFill`. Bundle ID: `io.river.MeowPassword.AutoFill`.

3. **Enable App Groups** on both the app and the extension:
   `Signing & Capabilities → + Capability → App Groups → group.io.river.MeowPassword`.
   The group lets the extension read config the main app writes.

4. **Set entitlements**. Xcode auto-fills:
   - `com.apple.developer.authentication-services.autofill-credential-provider = YES`

5. **Reuse `MeowRunner.swift`** by adding it to the extension target's
   membership. The extension can shell out to the bundled `meowpass` CLI
   the same way the main app does — but it must locate the binary via the
   *main* bundle, not the extension's bundle. Adjust `MeowRunner.binaryURL()`
   to walk up from the extension:
   ```swift
   Bundle.main.bundleURL              // .../PlugIns/MeowAutoFill.appex
       .deletingLastPathComponent()   // .../PlugIns
       .deletingLastPathComponent()   // .../Contents
       .appendingPathComponent("MacOS/meowpass")
   ```

## Extension implementation sketch

```swift
import AuthenticationServices

final class CredentialProviderViewController: ASCredentialProviderViewController {
    override func prepareInterfaceForPasskeyRegistration(_ registrationRequest: ASCredentialRequest) {
        // No-op — we don't do passkeys.
    }

    override func prepareInterfaceForExtensionConfiguration() {
        // Called from System Settings the first time the user enables us.
        extensionContext.completeExtensionConfigurationRequest()
    }

    /// Called by Safari's "Suggest Strong Password" flow.
    override func provideCredentialWithoutUserInteraction(for credentialIdentity: ASPasswordCredentialIdentity) {
        // MeowPassword generates rather than stores — deny.
        extensionContext.cancelRequest(withError: NSError(
            domain: ASExtensionErrorDomain,
            code: ASExtensionError.credentialIdentityNotFound.rawValue
        ))
    }

    /// The password-suggestion path.
    override func prepareInterface(forPasswordGeneration passwordCredentialIdentity: ASPasswordCredentialIdentity) {
        do {
            let result = try MeowRunner.generate(numbers: 3, symbols: 2, maxLength: 25)
            let credential = ASPasswordCredential(user: "", password: result.best)
            extensionContext.completeRequest(withSelectedCredential: credential, completionHandler: nil)
        } catch {
            extensionContext.cancelRequest(withError: error)
        }
    }
}
```

## Enabling it after install

1. Build in Xcode with a real Team (ad-hoc signing is fine locally, but
   AutoFill on user devices needs a proper signing identity).
2. Launch `MeowPassword.app` once — this registers the extension.
3. **System Settings → Passwords → Password Options →
   AutoFill Passwords From** → toggle on **MeowPassword**.
4. In Safari, on any sign-up form, click the password field →
   "Suggest Strong Password" → MeowPassword now appears alongside iCloud.

## What can't be done without a paid developer account

Apple gates AutoFill Credential Providers behind
`com.apple.developer.authentication-services.autofill-credential-provider`,
which requires a paid Apple Developer account and a Team ID for
distribution. For personal use / development on a single Mac, ad-hoc
signing plus a personal team works.

## Alternatives that need no Xcode target

- **Shortcuts / App Intents** — already shipped in this repo.
- **URL scheme** `meowpass://copy` — Raycast, Alfred, LaunchBar can invoke this.
- **Services menu** — right-click any password field → Services → Insert MeowPassword.
- **Menu bar item** — one-click generate + copy from anywhere.

For 90% of "generate a password right now" flows, those cover it. The
AutoFill extension is worth the Xcode setup if you want MeowPassword to
show up inside Safari's native password suggestion UI.
