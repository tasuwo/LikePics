//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Foundation

public class Effect<Action: CompositeKit.Action> {
    let id: UUID
    let upstream: AnyPublisher<Action?, Never>
    let actionAtCompleted: Action?
    let underlyingObject: Any?

    public init<P: Publisher>(_ publisher: P, completeWith action: Action? = nil) where P.Output == Action?, P.Failure == Never {
        self.id = UUID()
        self.upstream = publisher.eraseToAnyPublisher()
        self.underlyingObject = nil
        self.actionAtCompleted = action
    }

    public init<P: Publisher>(_ publisher: P, underlying object: Any?, completeWith action: Action? = nil) where P.Output == Action?, P.Failure == Never {
        self.id = UUID()
        self.upstream = publisher.eraseToAnyPublisher()
        self.underlyingObject = object
        self.actionAtCompleted = action
    }

    public init<P: Publisher>(id: UUID, publisher: P, underlying object: Any?, completeWith action: Action? = nil) where P.Output == Action?, P.Failure == Never {
        self.id = id
        self.upstream = publisher.eraseToAnyPublisher()
        self.underlyingObject = object
        self.actionAtCompleted = action
    }

    public init(value action: Action) {
        self.id = UUID()
        self.upstream = Just(action as Action?).eraseToAnyPublisher()
        self.underlyingObject = nil
        self.actionAtCompleted = nil
    }
}

public extension Effect {
    func map<T: CompositeKit.Action>(_ transform: @escaping (Action?) -> T?) -> Effect<T> {
        .init(id: id,
              publisher: upstream.map({ transform($0) }).eraseToAnyPublisher(),
              underlying: underlyingObject,
              completeWith: transform(actionAtCompleted))
    }
}
