//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct PureReducer<Action: CompositeKit.Action, State: Equatable, Dependency> {
    let reducer: (Action, State, Dependency) -> (State, [Effect<Action>]?)

    init(_ reducer: @escaping (Action, State, Dependency) -> (State, [Effect<Action>]?)) {
        self.reducer = reducer
    }
}

extension PureReducer: Reducer {
    public func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        reducer(action, state, dependency)
    }
}
