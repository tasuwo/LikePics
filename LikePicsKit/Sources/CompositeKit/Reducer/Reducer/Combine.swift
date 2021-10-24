//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public func combine<Reducer: CompositeKit.Reducer>(_ reducers: Reducer...) -> PureReducer<Reducer.Action, Reducer.State, Reducer.Dependency> {
    return PureReducer<Reducer.Action, Reducer.State, Reducer.Dependency> { action, state, dependency in
        var state = state
        var effects: [Effect<Reducer.Action>] = []

        for reducer in reducers {
            let (nextState, nextEffects) = reducer.execute(action: action, state: state, dependency: dependency)
            state = nextState
            effects += nextEffects ?? []
        }

        return (state, effects)
    }
}
