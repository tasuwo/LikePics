//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit
import Foundation

typealias SearchEntryViewDependency = HasClipSearchHistoryService
    & HasUserSettingStorage

struct SearchEntryViewReducer: Reducer {
    typealias Dependency = SearchEntryViewDependency
    typealias State = SearchEntryViewState
    typealias Action = SearchEntryViewAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return Self.prepare(nextState, dependency)

        // MARK: State Observation

        case let .searchHistoriesChanged(histories):
            nextState.searchHistories = histories
            return (nextState, nil)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            nextState.isSomeItemsHidden = isSomeItemsHidden
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

        case .alertDismissed:
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

        let historyStream = dependency.clipSearchHistoryService.query()
            .map { Action.searchHistoriesChanged($0) as Action? }
        let historyEffect = Effect(historyStream)

        let settingsStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.settingUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingsEffect = Effect(settingsStream)

        return (nextState, [historyEffect, settingsEffect])
    }
}
