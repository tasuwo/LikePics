//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import PromiseKit

func attempt<T>(maximumRetryCount: Int, delayBeforeRetry: DispatchTimeInterval, ignoredBy defaultValue: T? = nil, _ body: @escaping () -> Promise<T>) -> Promise<T> {
    var attempts = 0
    func attempt() -> Promise<T> {
        attempts += 1
        return body().recover { error -> Promise<T> in
            guard attempts < maximumRetryCount else {
                guard let defaultValue = defaultValue else {
                    throw error
                }
                return Promise { seal in
                    seal.resolve(.fulfilled(defaultValue))
                }
            }
            return after(delayBeforeRetry).then(on: nil, attempt)
        }
    }
    return attempt()
}
