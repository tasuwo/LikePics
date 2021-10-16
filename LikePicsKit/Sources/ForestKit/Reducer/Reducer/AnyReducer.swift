//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

private class ReducerBoxBase<Action: ForestKit.Action, State: Equatable, Dependency> {
    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        fatalError("Abstract method call")
    }
}

private class ReducerBox<Reducer: ForestKit.Reducer>: ReducerBoxBase<Reducer.Action, Reducer.State, Reducer.Dependency> {
    private let base: Reducer

    init(_ base: Reducer) {
        self.base = base
    }

    override func execute(action: Reducer.Action, state: Reducer.State, dependency: Reducer.Dependency) -> (Reducer.State, [Effect<Reducer.Action>]?) {
        base.execute(action: action, state: state, dependency: dependency)
    }
}

public struct AnyReducer<Action: ForestKit.Action, State: Equatable, Dependency> {
    private let box: ReducerBoxBase<Action, State, Dependency>

    public init<Reducer: ForestKit.Reducer>(_ base: Reducer) where Reducer.Action == Action, Reducer.State == State, Reducer.Dependency == Dependency {
        self.box = ReducerBox(base)
    }
}

extension AnyReducer: Reducer {
    // MARK: - Reducer

    public func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        box.execute(action: action, state: state, dependency: dependency)
    }
}
