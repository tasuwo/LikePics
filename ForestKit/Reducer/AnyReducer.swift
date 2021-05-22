//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct AnyReducer<Action: ForestKit.Action, State: Equatable, Dependency> {
    let reducer: (Action, State, Dependency) -> (State, [Effect<Action>]?)

    public init<R: Reducer>(reducer: R) where R.Action == Action, R.State == State, R.Dependency == Dependency {
        self.reducer = { reducer.execute(action: $0, state: $1, dependency: $2) }
    }

    public func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        return reducer(action, state, dependency)
    }
}
