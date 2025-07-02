//
//  Copyright ©︎ 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

public typealias Connection<Action: CompositeKit.Action> = AnyPublisher<Action?, Never>

extension Storing {
    public func connection<
        Property: Equatable,
        Action: CompositeKit.Action
    >(
        at keyPath: KeyPath<State, Property>,
        _ mapping: @escaping (Property) -> Action?
    ) -> Connection<Action> {
        state
            .removeDuplicates(by: keyPath)
            .map(keyPath)
            .map { mapping($0) }
            .eraseToAnyPublisher()
    }
}
