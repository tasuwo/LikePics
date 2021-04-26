//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

typealias SearchResultViewDependency = HasClipQueryService

enum SearchResultViewReducer: Reducer {
    typealias Dependency = SearchResultViewDependency
    typealias State = SearchResultViewState
    typealias Action = SearchResultViewAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        switch action {
        case let .searchQueryChanged(query):
            nextState.searchQuery = query

        case let .selectedTokenCandidate(token):
            nextState.searchQuery = state.searchQuery.appending(token: token)

        case .selectedResult(_):
            // TODO:
            break

        case .selectedSeeAllResultsButton:
            // TODO:
            break
        }
        return (nextState, nil)
    }
}
