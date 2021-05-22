//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct MergeReducer<State: Equatable, Action: ForestKit.Action, Dependency> {
    private let reducers: [UpstreamReducer<State, Action, Dependency>]

    // MARK: - Initializers

    public init(_ reducers: UpstreamReducer<State, Action, Dependency>...) {
        self.reducers = reducers
    }
}

extension MergeReducer: Reducer {
    public func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var currentState = state
        var currentEffects: [Effect<Action>] = []

        for reducer in reducers {
            let (nextState, effects) = reducer.execute(action: action, state: currentState, dependency: dependency)
            currentState = nextState
            currentEffects += effects ?? []
        }

        return (currentState, currentEffects)
    }
}
