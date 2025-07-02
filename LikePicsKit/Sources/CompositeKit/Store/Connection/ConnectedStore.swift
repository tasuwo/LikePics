//
//  Copyright ©︎ 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

public class ConnectedStore<State: Equatable, Action: CompositeKit.Action, Dependency> {
    private let store: AnyStoring<State, Action, Dependency>
    private let connection: Connection<Action>
    private var subscription: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    init(
        store: AnyStoring<State, Action, Dependency>,
        connection: Connection<Action>
    ) {
        self.store = store
        self.connection = connection

        bind()
    }

    // MARK: - Methods

    private func bind() {
        connection
            .compactMap { $0 }
            .sink { [weak self] in self?.store.execute($0) }
            .store(in: &subscription)
    }
}

extension ConnectedStore: Storing {
    // MARK: - Storing

    public var stateValue: State {
        store.stateValue
    }

    public var state: AnyPublisher<State, Never> {
        store.state
    }

    public func execute(_ action: Action) {
        store.execute(action)
    }
}

extension Storing {
    public func connect(
        _ connection: Connection<Action>
    ) -> ConnectedStore<State, Action, Dependency> {
        return .init(store: self.eraseToAnyStoring(), connection: connection)
    }
}
