//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

extension Publisher where Self.Failure == Never {
    public func removeDuplicates<Value>(by keyPath: KeyPath<Output, Value>) -> Publishers.RemoveDuplicates<Self> where Value: Equatable {
        removeDuplicates(by: { $0[keyPath: keyPath] == $1[keyPath: keyPath] })
    }
}
