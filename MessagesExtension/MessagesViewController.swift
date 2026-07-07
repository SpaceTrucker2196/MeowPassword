import UIKit
import SwiftUI
import Messages

/// The MeowGram iMessage app. Appears in the Messages app drawer (on iPhone,
/// iPad, and — synced from the iPhone — in Messages on Mac), letting you
/// compose a MeowGram and drop it straight into the conversation.
final class MessagesViewController: MSMessagesAppViewController {

    private var host: UIHostingController<MeowGramComposeView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        installUI()
    }

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        // Composing needs room — ask for the expanded presentation.
        if presentationStyle != .expanded {
            requestPresentationStyle(.expanded)
        }
    }

    private func installUI() {
        guard host == nil else { return }
        let root = MeowGramComposeView(
            isCompact: { [weak self] in self?.presentationStyle == .compact },
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

    /// Insert the embedded PNG into the conversation's input field as a
    /// lossless file attachment (so the hidden message survives).
    private func insertMeowGram(_ url: URL) {
        activeConversation?.insertAttachment(url, withAlternateFilename: url.lastPathComponent) { [weak self] _ in
            DispatchQueue.main.async { self?.requestPresentationStyle(.compact) }
        }
    }
}
