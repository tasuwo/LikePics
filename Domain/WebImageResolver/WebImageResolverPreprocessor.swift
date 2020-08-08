//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Erik
import PromiseKit

protocol WebImageResolverPreprocessor {
    func shouldPreprocess(url: URL) -> Bool
    func preprocess(_ browser: Erik, document: Document) -> Promise<Document>
}
