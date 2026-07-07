import UIKit
import SwiftUI
import Combine
import Messages

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
    private var host: UIHostingController<MeowGramComposeView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        let root = MeowGramComposeView(
            state: state,
            expand: { [weak self] in self?.requestPresentationStyle(.expanded) },
            insert: { [weak self] url in self?.insertMeowGram(url) }
        )
        let controller = UIHostingController(rootView: root)
        controller.view.backgroundColor = .clear
        addChild(controller)
        controller.view.frame = view.bounds
        controller.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(controller.view)
        controller.didMove(toParent: self)
        host = controller
    }

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        state.isExpanded = (presentationStyle == .expanded)
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
