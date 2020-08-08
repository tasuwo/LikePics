//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

class ClipTargetCollecitonViewController: UIViewController {
    private lazy var resolver: WebImageResolverProtocol = {
        return DispatchQueue.main.sync {
            let resolver = WebImageResolver()
            self.view.addSubview(resolver.webView)
            resolver.webView.isHidden = true
            return resolver
        }
    }()

    var images: [UIImage] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemGray
        self.setupNavBar()
    }

    // MARK: - Methods

    private func setupNavBar() {
        self.navigationItem.title = "My app"

        let itemCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
        self.navigationItem.setLeftBarButton(itemCancel, animated: false)

        let itemDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        self.navigationItem.setRightBarButton(itemDone, animated: false)
    }

    @objc private func cancelAction() {
        let error = NSError(domain: "net.tasuwo.TBox", code: 0, userInfo: [NSLocalizedDescriptionKey: "An error description"])
        extensionContext?.cancelRequest(withError: error)
    }

    @objc private func doneAction() {
        let attachment = self.extensionContext?.inputItems
            .compactMap { $0 as? NSExtensionItem }
            .compactMap { $0.attachments }
            .flatMap { $0 }
            .first(where: { $0.isUrl })

        attachment?.resolveUrl { result in
            switch result {
            case let .success(url):
                self.resolver.resolveWebImages(inUrl: url) { result in
                    switch result {
                    case let .success(urls):
                        self.images = urls
                            .compactMap { try? Data(contentsOf: $0) }
                            .compactMap { UIImage(data: $0) }
                    default:
                        break
                    }
                    self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                }
            default:
                self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
            }
        }
    }
}
