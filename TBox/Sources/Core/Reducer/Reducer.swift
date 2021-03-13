//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

protocol Reducer {
    associatedtype Action: LikePics.Action
    associatedtype State: Equatable
    associatedtype Dependency

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?)
}

extension Reducer {
    static func eraseToAnyReducer() -> AnyReducer<Action, State, Dependency> {
        return .init(reducer: self)
    }
}
