//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

class StoreProxy<
    State: Equatable,
    Action: LikePics.Action,
    Dependency,
    RootState: Equatable,
    RootAction: LikePics.Action,
    RootDependency
> {
    private let store: Store<RootState, RootAction, RootDependency>
    private let stateConverter: StateConverter<RootState, State>
    private let actionConverter: ActionConverter<RootAction, Action>

    init(
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

    var stateValue: State {
        stateConverter.extract(from: store.stateValue)
    }

    var state: AnyPublisher<State, Never> {
        store.state
            .map { [stateConverter] state in stateConverter.extract(from: state) }
            .eraseToAnyPublisher()
    }

    func execute(_ action: Action) {
        store.execute(actionConverter.convert(action))
    }
}

extension Store {
    func proxy<CS: Equatable, CA: LikePics.Action, CD>(
        _ stateConverter: StateConverter<State, CS>,
        _ actionConverter: ActionConverter<Action, CA>
    ) -> StoreProxy<CS, CA, CD, State, Action, Dependency> {
        return .init(store: self,
                     stateConverter: stateConverter,
                     actionConverter: actionConverter)
    }
}
