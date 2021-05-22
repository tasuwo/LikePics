//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

public class StoreProxy<
    State: Equatable,
    Action: ForestKit.Action,
    Dependency,
    RootState: Equatable,
    RootAction: ForestKit.Action,
    RootDependency
> {
    private let store: Store<RootState, RootAction, RootDependency>
    private let stateConverter: StateConverter<RootState, State>
    private let actionConverter: ActionConverter<RootAction, Action>

    public init(
        store: Store<RootState, RootAction, RootDependency>,
        stateConverter: StateConverter<RootState, State>,
        actionConverter: ActionConverter<RootAction, Action>
    ) {
        self.store = store
        self.stateConverter = stateConverter
        self.actionConverter = actionConverter
    }
}

extension StoreProxy: Storing {
    // MARK: - Storing

    public var stateValue: State {
        stateConverter.extract(from: store.stateValue)
    }

    public var state: AnyPublisher<State, Never> {
        store.state
            .map { [stateConverter] state in stateConverter.extract(from: state) }
            .eraseToAnyPublisher()
    }

    public func execute(_ action: Action) {
        store.execute(actionConverter.convert(action))
    }
}

public extension Store {
    func proxy<CS: Equatable, CA: ForestKit.Action, CD>(
        _ stateConverter: StateConverter<State, CS>,
        _ actionConverter: ActionConverter<Action, CA>
    ) -> StoreProxy<CS, CA, CD, State, Action, Dependency> {
        return .init(store: self,
                     stateConverter: stateConverter,
                     actionConverter: actionConverter)
    }
}
