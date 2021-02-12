//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

class Effect<Action: LikePics.Action> {
    let upstream: AnyPublisher<Action?, Never>
    private let underlyingObject: Any?

    init<P: Publisher>(_ publisher: P) where P.Output == Action?, P.Failure == Never {
        self.upstream = publisher.eraseToAnyPublisher()
        self.underlyingObject = nil
    }

    init<P: Publisher>(_ publisher: P, underlying object: Any) where P.Output == Action?, P.Failure == Never {
        self.upstream = publisher.eraseToAnyPublisher()
        self.underlyingObject = object
    }

    init(value action: Action) {
        self.upstream = Just(action as Action?).eraseToAnyPublisher()
        self.underlyingObject = nil
    }
}
