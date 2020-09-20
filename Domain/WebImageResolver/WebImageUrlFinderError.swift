//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum WebImageUrlFinderError: Error {
    case networkError(Error)
    case timeout
    case internalError
}
