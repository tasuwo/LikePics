//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import Foundation

enum SharedImageSource {
    case webPageURL(URL)
    case fileURL(URL)
    case data(ImageProvider)

    var isWebPageURL: Bool {
        switch self {
        case .webPageURL:
            return true

        default:
            return false
        }
    }

    var fileURL: URL? {
        switch self {
        case let .fileURL(url):
            return url

        default:
            return nil
        }
    }

    var data: LazyImageData? {
        switch self {
        case let .data(provider):
            return provider

        default:
            return nil
        }
    }
}
