//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol Storing {
    associatedtype State: Equatable
    associatedtype Action: ForestKit.Action
    associatedtype Dependency

    var stateValue: State { get }
    var state: AnyPublisher<State, Never> { get }
    func execute(_ action: Action)
}

public extension Storing {
    func eraseToAnyStoring() -> AnyStoring<State, Action, Dependency> {
        return .init(self)
    }
}

public struct StoreProxy_<State: Equatable, Action: ForestKit.Action, Dependency> {
    public let stateValue: State
    public let state: AnyPublisher<State, Never>
    let executeBlock: (Action) -> Void
}

extension StoreProxy_: Storing {
    // MARK: - Storing

    public func execute(_ action: Action) {
        executeBlock(action)
    }
}
