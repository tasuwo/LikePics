//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

struct AnyReducer<Action: LikePics.Action, State: Equatable, Dependency> {
    let reducer: (Action, State, Dependency) -> (State, [Effect<Action>]?)

    init<R: Reducer>(reducer: R) where R.Action == Action, R.State == State, R.Dependency == Dependency {
        self.reducer = { reducer.execute(action: $0, state: $1, dependency: $2) }
    }

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        return reducer(action, state, dependency)
    }
}
