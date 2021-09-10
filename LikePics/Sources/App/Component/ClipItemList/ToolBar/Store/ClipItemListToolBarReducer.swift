//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import ForestKit

typealias ClipItemListToolBarDependency = HasImageQueryService

struct ClipItemListToolBarReducer: Reducer {
    typealias Dependency = ClipItemListToolBarDependency
    typealias State = ClipItemListToolBarState
    typealias Action = ClipItemListToolBarAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return (state.updatingAppearance(), .none)

        // MARK: State Observation

        case let .selected(items):
            nextState.selectedItems = items
            return (nextState.updatingAppearance(), .none)

        // MARK: ToolBar

        case .editUrlButtonTapped:
            nextState.alert = .editUrl
            return (nextState, .none)

        case .shareButtonTapped:
            let imageIds = state.selectedItems.map(\.imageId)
            nextState.alert = .share(imageIds: imageIds, targetCount: nextState.selectedItems.count)
            return (nextState, .none)

        case .deleteButtonTapped:
            nextState.alert = .deletion(targetCount: state.selectedItems.count)
            return (nextState, .none)

        // MARK: Alert Completion

        case .alertDismissed,
             .alertDeleteConfirmed,
             .alertShareConfirmed,
             .alertSiteUrlEditted:
            nextState.alert = nil
            return (nextState, .none)
        }
    }
}

private extension ClipItemListToolBarState {
    func updatingAppearance() -> Self {
        var nextState = self
        let isEnabled = !selectedItems.isEmpty

        nextState.items = [
            Item(kind: .editUrl, isEnabled: isEnabled),
            Item(kind: .share, isEnabled: isEnabled),
            Item(kind: .delete, isEnabled: isEnabled)
        ]

        return nextState
    }
}
