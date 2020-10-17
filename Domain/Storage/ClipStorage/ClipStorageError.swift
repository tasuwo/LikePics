//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common

public enum ClipStorageError: Int, Error {
    case duplicated = 0
    case notFound
    case invalidParameter
    case internalError
}

extension ClipStorageError: ErrorCodeSource {
    public var factors: [ErrorCodeFactor] {
        return [
            .string("CSE"),
            .number(self.rawValue)
        ]
    }
}
