//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Erik
import PromiseKit

public protocol WebImageProvider {
    static func isProviding(url: URL) -> Bool

    static var shouldPreprocess: Bool { get }

    static func preprocess(_ browser: Erik, document: Document) -> Promise<Document>

    static var shouldModifyRequest: Bool { get }

    static func modifyRequest(_ request: URLRequest) -> URLRequest
}
