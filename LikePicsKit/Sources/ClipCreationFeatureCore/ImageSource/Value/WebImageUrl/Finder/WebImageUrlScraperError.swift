//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum WebImageUrlScraperError: Error {
    case networkError(Error)
    case timeout
    case internalError
}
