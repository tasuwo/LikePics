//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Foundation

public class WeakContainer<T> {
    private weak var internalValue: AnyObject?

    public var value: T? {
        return self.internalValue as? T
    }

    // MARK: - Lifecycle

    public init(value: T) {
        self.internalValue = value as AnyObject
    }
}
