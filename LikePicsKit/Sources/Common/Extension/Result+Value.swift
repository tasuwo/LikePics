//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

extension Result {
    public var successValue: Success? {
        guard case let .success(value) = self else { return nil }
        return value
    }

    public var failureValue: Failure? {
        guard case let .failure(error) = self else { return nil }
        return error
    }
}
