//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public func contramap<
    ParentState,
    ChildState,
    ParentAction,
    ChildAction,
    ParentDependency,
    ChildDependency,
    ChildReducer: Reducer
>(
    _ actionMap: ActionMapping<ParentAction, ChildAction>,
    _ stateMap: StateMapping<ParentState, ChildState>,
    _ transform: @escaping (ParentDependency) -> ChildDependency
) -> (ChildReducer) -> PureReducer<ParentAction, ParentState, ParentDependency>
    where ChildReducer.Action == ChildAction,
    ChildReducer.State == ChildState,
    ChildReducer.Dependency == ChildDependency
{
    return { reducer in contramap(actionMap)(contramap(stateMap)(contramap(transform)(reducer))) }
}

public func contramap<Parent, Child, ChildReducer: Reducer>(
    _ transform: @escaping (Parent) -> Child
) -> (ChildReducer) -> PureReducer<ChildReducer.Action, ChildReducer.State, Parent> where ChildReducer.Dependency == Child {
    return { reducer in
        return PureReducer { action, state, dependency in
            return reducer.execute(action: action, state: state, dependency: transform(dependency))
        }
    }
}

public func contramap<Parent, Child, ChildReducer: Reducer>(
    _ stateMapping: StateMapping<Parent, Child>
) -> (ChildReducer) -> PureReducer<ChildReducer.Action, Parent, ChildReducer.Dependency> where ChildReducer.State == Child {
    return { reducer in
        return PureReducer { action, state, dependency in
            let (childState, effects) = reducer.execute(action: action, state: stateMapping.get(state), dependency: dependency)
            let nextState = stateMapping.set(childState, state)
            return (nextState, effects)
        }
    }
}

public func contramap<Parent, Child, ChildReducer: Reducer>(
    _ actionMapping: ActionMapping<Parent, Child>
) -> (ChildReducer) -> PureReducer<Parent, ChildReducer.State, ChildReducer.Dependency> where ChildReducer.Action == Child {
    return { reducer in
        return PureReducer { action, state, dependency in
            guard let parentAction = actionMapping.get(action) else { return (state, []) }
            let (state, effects) = reducer.execute(action: parentAction, state: state, dependency: dependency)
            let nextEffects = effects?.map { effect in
                effect.map { childAction -> Parent? in
                    guard let action = childAction else { return nil }
                    return actionMapping.build(action)
                }
            }
            return (state, nextEffects)
        }
    }
}
