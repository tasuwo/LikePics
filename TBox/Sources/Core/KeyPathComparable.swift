//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

protocol KeyPathComparable {}

extension KeyPathComparable {
    func hasDifferentValue<T: Equatable>(at keyPath: KeyPath<Self, T>, from previousState: Self?) -> Bool {
        guard let previousState = previousState else { return true }
        return self[keyPath: keyPath] != previousState[keyPath: keyPath]
    }
}
