//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Erik
import PromiseKit

class TwitterWebImageResolverPreprocessor {
}

extension TwitterWebImageResolverPreprocessor: WebImageResolverPreprocessor {
    // MARK: - WebImageResolverPreprocessor

    func shouldPreprocess(url: URL) -> Bool {
        guard let host = url.host else { return false }
        return host.contains("twitter")
    }

    func preprocess(_ browser: Erik, document: Document) -> Promise<Document> {
        return Promise { seal in
            browser.currentContent { document, error in
                if let error = error {
                    seal.resolve(.rejected(WebImageResolverError.networkError(error)))
                    return
                }

                guard let document = document else {
                    seal.resolve(.rejected(WebImageResolverError.internalError))
                    return
                }

                // TODO: support multiple buttons
                guard let revealButton = document.querySelectorAll("span").first(where: {
                    guard let innerHtml = $0.innerHTML else { return false }
                    return innerHtml == "表示" || innerHtml == "View"
                }) else {
                    seal.resolve(.rejected(WebImageResolverError.internalError))
                    return
                }

                revealButton.click(completionHandler: { _, _ in
                    // TODO: Error Handling
                    DispatchQueue.global().async {
                        sleep(1)
                        seal.resolve(.fulfilled(document))
                    }
                })
            }
        }
    }
}
