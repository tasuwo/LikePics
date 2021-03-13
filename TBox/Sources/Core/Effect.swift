//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

class Effect<Action: LikePics.Action> {
    let upstream: AnyPublisher<Action?, Never>
    let actionAtCompleted: Action?
    private let underlyingObject: Any?

    init<P: Publisher>(_ publisher: P, completeWith action: Action? = nil) where P.Output == Action?, P.Failure == Never {
        self.upstream = publisher.eraseToAnyPublisher()
        self.underlyingObject = nil
        self.actionAtCompleted = action
    }

    init<P: Publisher>(_ publisher: P, underlying object: Any, completeWith action: Action? = nil) where P.Output == Action?, P.Failure == Never {
        self.upstream = publisher.eraseToAnyPublisher()
        self.underlyingObject = object
        self.actionAtCompleted = action
    }

    init(value action: Action) {
        self.upstream = Just(action as Action?).eraseToAnyPublisher()
        self.underlyingObject = nil
        self.actionAtCompleted = nil
    }
}
