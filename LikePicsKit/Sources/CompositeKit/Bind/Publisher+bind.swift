//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

extension Publisher where Self.Failure == Never {
    public func bind<Value, Root>(
        _ fromKeyPath: KeyPath<Output, Value>,
        to toKeyPath: ReferenceWritableKeyPath<Root, Value>,
        on object: Root
    ) -> AnyCancellable where Root: AnyObject, Value: Equatable {
        map(fromKeyPath)
            .removeDuplicates()
            .assign(to: toKeyPath, on: object)
    }

    public func bindNoRetain<Value, Root>(
        _ fromKeyPath: KeyPath<Output, Value>,
        to toKeyPath: ReferenceWritableKeyPath<Root, Value>,
        on object: Root
    ) -> AnyCancellable where Root: AnyObject, Value: Equatable {
        map(fromKeyPath)
            .removeDuplicates()
            .sink { [weak object] value in
                guard let object = object else { return }
                _ = Just(value).assign(to: toKeyPath, on: object)
            }
    }

    public func bind<Value>(
        _ keyPath: KeyPath<Output, Value>,
        receiveCompletion: @escaping ((Subscribers.Completion<Self.Failure>) -> Void),
        receiveValue: @escaping ((Value) -> Void)
    ) -> AnyCancellable where Value: Equatable {
        removeDuplicates(by: keyPath)
            .map(keyPath)
            .sink(receiveCompletion: receiveCompletion, receiveValue: receiveValue)
    }

    public func bind<Value>(
        _ keyPath: KeyPath<Output, Value>,
        receiveValue: @escaping ((Value) -> Void)
    ) -> AnyCancellable where Value: Equatable {
        bind(keyPath, receiveCompletion: { _ in }, receiveValue: receiveValue)
    }
}
