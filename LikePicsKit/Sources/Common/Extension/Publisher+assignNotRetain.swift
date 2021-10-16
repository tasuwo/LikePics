//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

public extension Publisher where Self.Failure == Never {
    func assignNoRetain<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, on object: Root) -> AnyCancellable where Root: AnyObject {
        sink { [weak object] value in
            guard let object = object else { return }
            _ = Just(value).assign(to: keyPath, on: object)
        }
    }
}
