//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

class Store<S: Equatable, A: Action, D> {
    typealias Reducer = (A, S, D) -> S

    var stateValue: S { _state.value }
    var state: AnyPublisher<S, Never> { _state.eraseToAnyPublisher() }

    private let dependency: D
    private let reducer: Reducer
    private let _state: CurrentValueSubject<S, Never>

    // MARK: - Initializers

    init(initialState: S, dependency: D, reducer: @escaping Reducer) {
        self.dependency = dependency
        self.reducer = reducer
        self._state = .init(initialState)
    }

    // MARK: - Methods

    func execute(_ action: A) {
        _state.send(reducer(action, _state.value, dependency))
    }
}
