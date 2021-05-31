//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

enum ImageSource {
    case webUrl(URL)
    case fileUrl(URL)
    case data(ImageProvider)

    var isWebUrl: Bool {
        switch self {
        case .webUrl:
            return true

        default:
            return false
        }
    }

    var fileUrl: URL? {
        switch self {
        case let .fileUrl(url):
            return url

        default:
            return nil
        }
    }

    var imageProvider: ImageProvider? {
        switch self {
        case let .data(provider):
            return provider

        default:
            return nil
        }
    }
}
