import UIKit
import SwiftUI
import UniformTypeIdentifiers
import MeowGramKit

/// Share-sheet target "Decode MeowGram": receives a shared image (from
/// Messages, Photos, Files, …) and hands it to the MeowPassword app, which
/// opens on its decode screen with the image loaded. Falls back to decoding
/// inline if the app can't be opened (e.g. App Group unavailable).
@objc(ShareViewController)
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        loadSharedImageData { [weak self] data in
            DispatchQueue.main.async { self?.handle(data) }
        }
    }

    private func handle(_ data: Data?) {
        // Preferred path: drop the image in the shared inbox and open the app
        // straight to its decode screen.
        if let data, MeowGramInbox.isAvailable, MeowGramInbox.write(data),
           let url = URL(string: "meowpass://decode") {
            openContainingApp(url)
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }
        // Fallback: decode inline in the share sheet.
        presentInlineDecode(data)
    }

    private func presentInlineDecode(_ data: Data?) {
        let root = ShareDecodeView(imageData: data, close: { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        })
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear
        host.overrideUserInterfaceStyle = .light
        overrideUserInterfaceStyle = .light
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
    }

    /// Open the containing app from the extension (walk the responder chain to
    /// a UIApplication that responds to openURL:).
    private func openContainingApp(_ url: URL) {
        var responder: UIResponder? = self
        let selector = sel_registerName("openURL:")
        while let r = responder {
            if r.responds(to: selector) {
                _ = r.perform(selector, with: url)
                return
            }
            responder = r.next
        }
    }

    /// Pull the shared image out as raw bytes, preferring exact PNG data
    /// (lossless — the stego payload only survives if the pixels are intact).
    private func loadSharedImageData(completion: @escaping (Data?) -> Void) {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let provider = item.attachments?.first(where: {
                  $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
              }) else { completion(nil); return }

        if provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) {
            provider.loadDataRepresentation(forTypeIdentifier: UTType.png.identifier) { data, _ in
                completion(data)
            }
            return
        }
        provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
            if let url = item as? URL, let d = try? Data(contentsOf: url) { completion(d) }
            else if let d = item as? Data { completion(d) }
            else if let img = item as? UIImage { completion(img.pngData()) }
            else { completion(nil) }
        }
    }
}
