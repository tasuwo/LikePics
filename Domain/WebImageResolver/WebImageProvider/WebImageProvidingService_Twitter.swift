//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Erik
import PromiseKit

extension WebImageProvidingService {
    public enum Twitter: WebImageProvider {
        // MARK: - WebImageProvider

        public static func isProviding(url: URL) -> Bool {
            guard let host = url.host else { return false }
            return host.contains("twitter")
        }

        public static var shouldPreprocess: Bool {
            return true
        }

        public static func preprocess(_ browser: Erik, document: Document) -> Promise<Document> {
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

        public static var shouldModifyRequest: Bool {
            return false
        }

        public static func modifyRequest(_ request: URLRequest) -> URLRequest {
            return request
        }
    }
}
