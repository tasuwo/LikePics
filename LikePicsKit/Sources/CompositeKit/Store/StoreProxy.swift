//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

public class StoreProxy<
    ChildState: Equatable,
    ChildAction: CompositeKit.Action,
    Dependency,
    ParentState: Equatable,
    ParentAction: CompositeKit.Action,
    ParentDependency
> {
    private let store: Store<ParentState, ParentAction, ParentDependency>
    private let stateMapping: StateMapping<ParentState, ChildState>
    private let actionMapping: ActionMapping<ParentAction, ChildAction>

    public init(
        store: Store<ParentState, ParentAction, ParentDependency>,
        stateMapping: StateMapping<ParentState, ChildState>,
        actionMapping: ActionMapping<ParentAction, ChildAction>
    ) {
        self.store = store
        self.stateMapping = stateMapping
        self.actionMapping = actionMapping
    }
}

extension StoreProxy: Storing {
    // MARK: - Storing

    public var stateValue: ChildState {
        stateMapping.get(store.stateValue)
    }

    public var state: AnyPublisher<ChildState, Never> {
        store.state
            .map { [stateMapping] state in stateMapping.get(state) }
            .eraseToAnyPublisher()
    }

    public func execute(_ action: ChildAction) {
        store.execute(actionMapping.build(action))
    }
}

public extension Store {
    func proxy<
        ChildState: Equatable,
        ChildAction: CompositeKit.Action,
        ChildDependency
    >(
        _ stateMapping: StateMapping<State, ChildState>,
        _ actionMapping: ActionMapping<Action, ChildAction>
    ) -> StoreProxy<
        ChildState,
        ChildAction,
        ChildDependency,
        State,
        Action,
        Dependency
    > {
        return .init(store: self,
                     stateMapping: stateMapping,
                     actionMapping: actionMapping)
    }
}
