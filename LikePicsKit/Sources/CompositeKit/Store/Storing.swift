//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol Storing {
    associatedtype State: Equatable
    associatedtype Action: CompositeKit.Action
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
