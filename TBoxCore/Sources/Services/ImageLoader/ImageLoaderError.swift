//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum ImageLoaderError: Error {
    case networkError(Error)
    case internalError
}
