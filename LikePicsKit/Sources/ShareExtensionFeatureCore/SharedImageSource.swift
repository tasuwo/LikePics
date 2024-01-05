//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import Foundation

public enum SharedImageSource {
    case webPageURL(URL)
    case fileURL(URL)
    case data(LazyImageData)

    public var isWebPageURL: Bool {
        switch self {
        case .webPageURL:
            return true

        default:
            return false
        }
    }

    public var fileURL: URL? {
        switch self {
        case let .fileURL(url):
            return url

        default:
            return nil
        }
    }

    public var data: LazyImageData? {
        switch self {
        case let .data(data):
            return data

        default:
            return nil
        }
    }
}
