import UIKit
import SwiftUI
import UniformTypeIdentifiers
import MeowUI
import MeowGramKit

/// Share-sheet target "Decode MeowGram": receives a shared image (from
/// Messages, Photos, Files, …) and decodes it inline, right in the share
/// sheet. (iOS does not let a share extension reliably launch its host app,
/// so we do the decode here rather than trying to open MeowPassword.)
@objc(ShareViewController)
final class ShareViewController: UIViewController {

    private let themeManager = ThemeManager()
    private var host: UIHostingController<AnyView>?
    private var imageData: Data?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        loadSharedImageData { [weak self] data in
            DispatchQueue.main.async { self?.presentInlineDecode(data) }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        themeManager.reload()
        host?.rootView = themedRoot()
        applyInterfaceStyle(to: host)
    }

    private func presentInlineDecode(_ data: Data?) {
        imageData = data
        let host = UIHostingController(rootView: themedRoot())
        host.view.backgroundColor = .clear
        applyInterfaceStyle(to: host)
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
        self.host = host
    }

    private func themedRoot() -> AnyView {
        AnyView(
            ShareDecodeView(imageData: imageData, close: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            })
            .environment(\.theme, themeManager.current)
            .preferredColorScheme(themeManager.current.colorScheme)
        )
    }

    private func applyInterfaceStyle(to host: UIHostingController<AnyView>?) {
        let style: UIUserInterfaceStyle = themeManager.current.prefersDark ? .dark : .light
        host?.overrideUserInterfaceStyle = style
        overrideUserInterfaceStyle = style
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
