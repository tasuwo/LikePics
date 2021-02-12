//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Foundation

class Store<State: Equatable, A: Action, Dependency> {
    typealias Reducer = (A, State, Dependency) -> (State, Effect?)
    typealias Effect = AnyPublisher<A?, Never>

    var stateValue: State { _state.value }
    var state: AnyPublisher<State, Never> { _state.eraseToAnyPublisher() }

    weak var republisher: ActionRepublisher?

    private let dependency: Dependency
    private let reducer: Reducer
    private let _state: CurrentValueSubject<State, Never>

    private var effects: [UUID: Effect] = [:]
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(initialState: State, dependency: Dependency, reducer: @escaping Reducer) {
        self.dependency = dependency
        self.reducer = reducer
        self._state = .init(initialState)
    }

    // MARK: - Methods

    func execute(_ action: A) {
        if Thread.isMainThread {
            _execute(action)
        } else {
            DispatchQueue.main.async {
                self._execute(action)
            }
        }
    }

    private func _execute(_ action: A) {
        let (nextState, effect) = reducer(action, _state.value, dependency)

        _state.send(nextState)
        republisher?.republishIfNeeded(action, for: self)

        if let effect = effect { schedule(effect) }
    }

    private func schedule(_ effect: Effect) {
        let id = UUID()

        effects[id] = effect

        effect
            .sink { [weak self] _ in
                self?.effects.removeValue(forKey: id)
            } receiveValue: { [weak self] action in
                guard let action = action else { return }
                self?.execute(action)
            }
            .store(in: &subscriptions)
    }
}
