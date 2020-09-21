//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Erik
import PromiseKit

public protocol WebImageProvider {
    static func isProviding(url: URL) -> Bool

    static func modifyUrlForProcessing(_ url: URL) -> URL

    static func shouldPreprocess(for url: URL) -> Bool

    static func preprocess(_ browser: Erik, document: Document) -> Promise<Document>

    static func resolveLowQualityImageUrl(of url: URL) -> URL?

    static func resolveHighQualityImageUrl(of url: URL) -> URL?

    static func shouldModifyRequest(for url: URL) -> Bool

    static func modifyRequest(_ request: URLRequest) -> URLRequest
}
