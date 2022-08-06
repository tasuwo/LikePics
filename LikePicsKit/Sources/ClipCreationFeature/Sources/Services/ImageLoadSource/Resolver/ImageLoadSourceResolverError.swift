//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum ImageLoadSourceResolverError: Error {
    case networkError(Error)
    case timeout
    case internalError
    case notFound

    init(finderError: WebImageUrlSetFinderError) {
        switch finderError {
        case .internalError:
            self = .internalError

        case .timeout:
            self = .timeout

        case let .networkError(error):
            self = .networkError(error)
        }
    }
}
