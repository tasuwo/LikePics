//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import Social
import UIKit

class ShareViewController: SLComposeServiceViewController {
    private lazy var resolver: WebImageResolverProtocol = {
        return DispatchQueue.main.sync {
            let resolver = WebImageResolver()
            self.view.addSubview(resolver.webView)
            resolver.webView.isHidden = true
            return resolver
        }
    }()

    var images: [UIImage] = []

    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
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

    override func configurationItems() -> [Any]! {
        return []
    }
}
