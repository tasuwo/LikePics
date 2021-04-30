//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

typealias SearchEntryViewDependency = HasClipSearchHistoryService

enum SearchEntryViewReducer: Reducer {
    typealias Dependency = SearchEntryViewDependency
    typealias State = SearchEntryViewState
    typealias Action = SearchEntryViewAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return prepare(nextState, dependency)

        // MARK: State Observation

        case let .searchHistoriesChanged(histories):
            nextState.searchHistories = histories
            return (nextState, nil)

        // MARK: Search History

        case let .removedHistory(history, completion: completion):
            guard let index = nextState.searchHistories.firstIndex(where: { $0.id == history.id }) else {
                completion(false)
                return (nextState, nil)
            }
            dependency.clipSearchHistoryService.remove(historyHaving: history.id)
            nextState.searchHistories.remove(at: index)
            return (nextState, nil)

        case .removeAllHistories:
            nextState.alert = .removeAll
            return (nextState, nil)

        // MARK: Alert Completion

        case .alertDeleteConfirmed:
            dependency.clipSearchHistoryService.removeAll()
            nextState.searchHistories = []
            nextState.alert = nil
            return (nextState, nil)
        }
    }
}

// MARK: - Preparation

extension SearchEntryViewReducer {
    private static func prepare(_ state: State, _ dependency: Dependency) -> (State, [Effect<Action>]) {
        var nextState = state

        nextState.searchHistories = dependency.clipSearchHistoryService.read()

        let stream = dependency.clipSearchHistoryService.query()
            .map { Action.searchHistoriesChanged($0) as Action? }

        return (nextState, [Effect(stream)])
    }
}
