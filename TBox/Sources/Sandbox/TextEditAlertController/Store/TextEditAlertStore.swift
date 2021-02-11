//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

class TextEditAlertStore {
    typealias Reducer = TextEditAlertReducer

    var stateValue: Reducer.State { _state.value }
    var state: AnyPublisher<Reducer.State, Never> { _state.eraseToAnyPublisher() }

    private let dependency: Reducer.Dependency
    private let _state: CurrentValueSubject<Reducer.State, Never>

    // MARK: - Lifecycle

    init(dependency: Reducer.Dependency, state: Reducer.State) {
        self.dependency = dependency
        self._state = .init(state)
    }

    // MARK: - Methods

    func execute(_ action: Reducer.Action) {
        _state.send(Reducer.execute(action: action, state: _state.value, dependency: dependency))
    }
}
