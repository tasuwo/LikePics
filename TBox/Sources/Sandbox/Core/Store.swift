//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Foundation

class Store<State: Equatable, Action: LikePics.Action, Dependency> {
    var stateValue: State { _state.value }
    var state: AnyPublisher<State, Never> { _state.eraseToAnyPublisher() }

    weak var publisher: ActionPublisher?

    private let dependency: Dependency
    private let reducer: AnyReducer<Action, State, Dependency>
    private let _state: CurrentValueSubject<State, Never>

    private var effects: [UUID: Effect<Action>] = [:]
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init<R: Reducer>(initialState: State, dependency: Dependency, reducer: R.Type) where R.Action == Action, R.State == State, R.Dependency == Dependency {
        self._state = .init(initialState)
        self.dependency = dependency
        self.reducer = reducer.eraseToAnyReducer()
    }

    // MARK: - Methods

    func execute(_ action: Action) {
        if Thread.isMainThread {
            _execute(action)
        } else {
            DispatchQueue.main.async {
                self._execute(action)
            }
        }
    }

    private func _execute(_ action: Action) {
        let (nextState, effects) = reducer.execute(action: action, state: _state.value, dependency: dependency)

        _state.send(nextState)
        publisher?.publish(action, for: self)

        if let effects = effects { effects.forEach { schedule($0) } }
    }

    private func schedule(_ effect: Effect<Action>) {
        let id = UUID()

        effects[id] = effect

        effect.upstream
            .sink { [weak self] _ in
                self?.effects.removeValue(forKey: id)
            } receiveValue: { [weak self] action in
                guard let action = action else { return }
                self?.execute(action)
            }
            .store(in: &subscriptions)
    }
}
