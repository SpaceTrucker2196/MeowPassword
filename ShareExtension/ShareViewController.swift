import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// Share-sheet target "Decode MeowGram": receives a shared image (from
/// Messages, Photos, Files, …), extracts the hidden message, and shows it.
@objc(ShareViewController)
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        loadSharedImageData { [weak self] data in
            DispatchQueue.main.async { self?.present(data: data) }
        }
    }

    private func present(data: Data?) {
        let root = ShareDecodeView(imageData: data, close: { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        })
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
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
