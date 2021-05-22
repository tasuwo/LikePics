//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct UpstreamReducer<State: Equatable, Action: ForestKit.Action, Dependency> {
    private let executeBlock: (Action, State, Dependency) -> (State, [Effect<Action>]?)

    public init<R: Reducer, SC: StateConvertible, AC: ActionConvertible>(
        reducer: R,
        stateConverter: SC,
        actionConverter: AC,
        dependencyCaster: @escaping (Dependency) -> R.Dependency
    ) where
        R.State == SC.Child,
        R.Action == AC.Child,
        State == SC.Parent,
        Action == AC.Parent
    {
        self.executeBlock = { action, state, dependency -> (State, [Effect<Action>]?) in
            guard let childAction = actionConverter.extract(from: action) else {
                return (state, nil)
            }

            let childState = stateConverter.extract(from: state)
            let childDependency = dependencyCaster(dependency)
            let (nextState, nextEffects) = reducer.execute(action: childAction, state: childState, dependency: childDependency)

            return (
                stateConverter.merging(nextState, to: state),
                nextEffects?.map({ effect in
                    effect.map({
                        guard let action = $0 else { return nil }
                        return actionConverter.convert(action)
                    })
                })
            )
        }
    }
}

extension UpstreamReducer: Reducer {
    public func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        self.executeBlock(action, state, dependency)
    }
}

public extension Reducer {
    func upstream<PS: Equatable, PA: ForestKit.Action, PD>(
        _ stateConverter: StateConverter<PS, State>,
        _ actionConverter: ActionConverter<PA, Action>,
        _ dependencyCaster: @escaping (PD) -> Dependency
    ) -> UpstreamReducer<PS, PA, PD> {
        .init(reducer: self,
              stateConverter: stateConverter,
              actionConverter: actionConverter,
              dependencyCaster: dependencyCaster)
    }
}
