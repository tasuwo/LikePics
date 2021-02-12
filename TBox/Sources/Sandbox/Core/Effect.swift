//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

class Effect<A: Action> {
    let upstream: AnyPublisher<A?, Never>
    private let underlyingObject: Any?

    init<P: Publisher>(_ publisher: P) where P.Output == A?, P.Failure == Never {
        self.upstream = publisher.eraseToAnyPublisher()
        self.underlyingObject = nil
    }

    init<P: Publisher>(_ publisher: P, underlying object: Any) where P.Output == A?, P.Failure == Never {
        self.upstream = publisher.eraseToAnyPublisher()
        self.underlyingObject = object
    }
}
