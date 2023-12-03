//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import Environment
import Foundation

public typealias ClipsIntegrityValidatorDependency = HasIntegrityValidationService
    & HasTemporariesPersistService

struct ClipsIntegrityValidatorReducer: Reducer {
    typealias Dependency = ClipsIntegrityValidatorDependency
    typealias State = ClipsIntegrityValidatorState
    typealias Action = ClipsIntegrityValidatorAction

    let queue = DispatchQueue(label: "net.tasuwo.TBox.ClipsIntegrityValidatorReducer")

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        case .didLaunchApp:
            guard !nextState.state.isLoading else { return (nextState, .none) }
            let stream = Deferred {
                Future<Action?, Never> { promise in
                    queue.async {
                        _ = dependency.temporariesPersistService.persistIfNeeded()
                        dependency.integrityValidationService.validateAndFixIntegrityIfNeeded()
                        promise(.success(.didFinishLoading))
                    }
                }
            }
            nextState.state = .loading(currentIndex: nil, counts: nil)
            return (nextState, [Effect(stream)])

        case .shareExtensionDidCompleteRequest:
            guard !nextState.state.isLoading else { return (nextState, .none) }
            let stream = Deferred {
                Future<Action?, Never> { promise in
                    queue.async {
                        if dependency.temporariesPersistService.persistIfNeeded() == false {
                            dependency.integrityValidationService.validateAndFixIntegrityIfNeeded()
                        }
                        promise(.success(.didFinishLoading))
                    }
                }
            }
            nextState.state = .loading(currentIndex: nil, counts: nil)
            return (nextState, [Effect(stream)])

        case let .didStartLoading(index: index, count: count):
            guard nextState.state.isLoading else { return (nextState, .none) }
            nextState.state = .loading(currentIndex: index, counts: count)
            return (nextState, .none)

        case .didFinishLoading:
            nextState.state = .stopped
            return (nextState, .none)
        }
    }
}
