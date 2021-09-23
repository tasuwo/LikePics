//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public enum ImageSource {
    case provider(ImageDataProviding)

    var cacheKey: String {
        switch self {
        case let .provider(provider):
            return provider.cacheKey
        }
    }
}
