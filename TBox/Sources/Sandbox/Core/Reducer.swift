//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

protocol Reducer {
    associatedtype Dependency
    associatedtype State
    associatedtype Action

    static func execute(action: Action, state: State, dependency: Dependency) -> State
}
