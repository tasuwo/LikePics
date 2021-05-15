//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

protocol Storing {
    associatedtype State: Equatable
    associatedtype Action: LikePics.Action
    associatedtype Dependency

    var stateValue: State { get }
    var state: AnyPublisher<State, Never> { get }
    func execute(_ action: Action)
}

extension Storing {
    func eraseToAnyStoring() -> AnyStoring<State, Action, Dependency> {
        return .init(self)
    }
}
