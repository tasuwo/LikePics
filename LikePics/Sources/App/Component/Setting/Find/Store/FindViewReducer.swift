//
//  Copyright © 2022 Tasuku Tozawa. All rights reserved.
//

import CompositeKit
import Foundation

typealias FindViewDependency = HasNop

struct FindViewReducer: Reducer {
    typealias Dependency = FindViewDependency
    typealias State = FindViewState
    typealias Action = FindViewAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        switch action {
        case let .updatedTitle(title):
            nextState.title = title

        case let .updatedUrl(url):
            nextState.currentUrl = url

        case let .updatedCanGoBack(canGoBack):
            nextState.canGoBack = canGoBack

        case let .updatedCanGoForward(canGoForward):
            nextState.canGoForward = canGoForward

        case let .updatedLoading(isLoading):
            nextState.isLoading = isLoading

        case let .updatedEstimatedProgress(progress):
            nextState.estimatedProgress = progress

        case .tapClip:
            nextState.modal = .clipCreation(id: UUID())

        case .modalDismissed:
            nextState.modal = nil
        }
        return (nextState, .none)
    }
}
