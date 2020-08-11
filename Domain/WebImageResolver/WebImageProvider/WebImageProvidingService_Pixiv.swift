//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Erik
import PromiseKit

extension WebImageProvidingService {
    public enum Pixiv: WebImageProvider {
        // MARK: - WebImageProvider

        public static func isProviding(url: URL) -> Bool {
            guard let host = url.host else { return false }
            return host.contains("pximg")
        }

        public static var shouldPreprocess: Bool {
            return false
        }

        public static func preprocess(_ browser: Erik, document: Document) -> Promise<Document> {
            return Promise { $0.resolve(.fulfilled(document)) }
        }

        public static func composeUrl(lowerQualityOf url: URL) -> URL {
            return url
        }

        public static func composeUrl(higherQualityOf url: URL) -> URL {
            return url
        }

        public static var shouldModifyRequest: Bool {
            return true
        }

        public static func modifyRequest(_ request: URLRequest) -> URLRequest {
            var r = request
            r.setValue("http://www.pixiv.net/", forHTTPHeaderField: "Referer")
            return r
        }
    }
}
