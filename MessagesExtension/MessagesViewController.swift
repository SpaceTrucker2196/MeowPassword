import UIKit
import SwiftUI
import Combine
import Messages
import MeowUI

/// Observable bridge so the SwiftUI compose view reacts when Messages
/// transitions the extension between compact and expanded presentation.
final class ExtensionState: ObservableObject {
    @Published var isExpanded: Bool = false
}

/// The MeowGram iMessage app. Appears in the Messages app drawer (on iPhone,
/// iPad, and — synced from the iPhone — in Messages on Mac), letting you
/// compose a MeowGram and drop it straight into the conversation.
final class MessagesViewController: MSMessagesAppViewController {

    private let state = ExtensionState()
    private let themeManager = ThemeManager()
    private var host: UIHostingController<AnyView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        let controller = UIHostingController(rootView: themedRoot())
        controller.view.backgroundColor = .clear
        // Force the theme's fixed scheme regardless of the Messages host's
        // light/dark appearance, so text never lands white-on-white.
        applyInterfaceStyle(to: controller)
        addChild(controller)
        controller.view.frame = view.bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(controller.view)
        controller.didMove(toParent: self)
        host = controller
    }

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        themeManager.reload()
        host?.rootView = themedRoot()
        applyInterfaceStyle(to: host)
        state.isExpanded = (presentationStyle == .expanded)
    }

    private func themedRoot() -> AnyView {
        AnyView(
            MeowGramComposeView(
                state: state,
                expand: { [weak self] in self?.requestPresentationStyle(.expanded) },
                insert: { [weak self] url in self?.insertMeowGram(url) }
            )
            .environment(\.theme, themeManager.current)
            .preferredColorScheme(themeManager.current.colorScheme)
        )
    }

    private func applyInterfaceStyle(to host: UIHostingController<AnyView>?) {
        let style: UIUserInterfaceStyle = themeManager.current.prefersDark ? .dark : .light
        host?.overrideUserInterfaceStyle = style
        overrideUserInterfaceStyle = style
    }

    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.didTransition(to: presentationStyle)
        // Drive the SwiftUI view: show the composer only once expanded.
        state.isExpanded = (presentationStyle == .expanded)
    }

    /// Insert the embedded PNG into the conversation's input field as a
    /// lossless file attachment (so the hidden message survives).
    private func insertMeowGram(_ url: URL) {
        activeConversation?.insertAttachment(url, withAlternateFilename: url.lastPathComponent) { [weak self] _ in
            DispatchQueue.main.async { self?.requestPresentationStyle(.compact) }
        }
    }
}
