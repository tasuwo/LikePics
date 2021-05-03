//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

extension Publisher where Self.Failure == Never {
    func bind<Value, Root>(_ fromKeyPath: KeyPath<Output, Value>,
                           to toKeyPath: ReferenceWritableKeyPath<Root, Value>,
                           on object: Root) -> AnyCancellable where Root: AnyObject, Value: Equatable
    {
        map(fromKeyPath)
            .removeDuplicates()
            .assign(to: toKeyPath, on: object)
    }

    func bindNoRetain<Value, Root>(_ fromKeyPath: KeyPath<Output, Value>,
                                   to toKeyPath: ReferenceWritableKeyPath<Root, Value>,
                                   on object: Root) -> AnyCancellable where Root: AnyObject, Value: Equatable
    {
        map(fromKeyPath)
            .removeDuplicates()
            .sink { [weak object] value in
                guard let object = object else { return }
                _ = Just(value).assign(to: toKeyPath, on: object)
            }
    }
}
