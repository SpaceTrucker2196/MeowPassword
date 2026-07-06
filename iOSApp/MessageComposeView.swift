import SwiftUI
import MessageUI
import UniformTypeIdentifiers

/// Presents the system Messages compose sheet with a MeowGram PNG attached.
/// Attaching the PNG file (not an inline image) keeps the bytes lossless so
/// the hidden message survives.
struct MessageComposeView: UIViewControllerRepresentable {
    let attachmentURL: URL
    let body: String
    var onFinish: () -> Void

    static var canSend: Bool { MFMessageComposeViewController.canSendText() }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let vc = MFMessageComposeViewController()
        vc.messageComposeDelegate = context.coordinator
        vc.body = body
        if MFMessageComposeViewController.canSendAttachments(),
           let data = try? Data(contentsOf: attachmentURL) {
            vc.addAttachmentData(data,
                                 typeIdentifier: UTType.png.identifier,
                                 filename: attachmentURL.lastPathComponent)
        }
        return vc
    }

    func updateUIViewController(_ vc: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onFinish: onFinish) }

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        let onFinish: () -> Void
        init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
        func messageComposeViewController(_ controller: MFMessageComposeViewController,
                                          didFinishWith result: MessageComposeResult) {
            onFinish()
        }
    }
}
