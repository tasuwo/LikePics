//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

extension Publisher where Self.Failure == Never {
    func onChange<Value>(_ keyPath: KeyPath<Output, Value>,
                         receiveCompletion: @escaping ((Subscribers.Completion<Self.Failure>) -> Void),
                         receiveValue: @escaping ((Value) -> Void)) -> AnyCancellable where Value: Equatable
    {
        removeDuplicates(by: keyPath)
            .map(keyPath)
            .sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
    }

    func onChange<Value>(_ keyPath: KeyPath<Output, Value>,
                         receiveValue: @escaping ((Value) -> Void)) -> AnyCancellable where Value: Equatable
    {
        onChange(keyPath, receiveCompletion: { _ in }, receiveValue: receiveValue)
    }
}
