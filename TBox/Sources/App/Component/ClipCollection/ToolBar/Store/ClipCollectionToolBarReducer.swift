//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

typealias ClipCollectionToolBarDependency = HasImageQueryService

struct ClipCollectionToolBarReducer: Reducer {
    typealias Dependency = ClipCollectionToolBarDependency
    typealias State = ClipCollectionToolBarState
    typealias Action = ClipCollectionToolBarAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return (state.updatingAppearance(), .none)

        // MARK: State Observation

        case .stateChanged:
            nextState = nextState.updatingAppearance()
            return (nextState, .none)

        // MARK: ToolBar

        case .addButtonTapped:
            nextState.alert = .addition(targetCount: nextState.parentState.clips.selectedIds().count)
            return (nextState, .none)

        case .changeVisibilityButtonTapped:
            nextState.alert = .changeVisibility(targetCount: nextState.parentState.clips.selectedIds().count)
            return (nextState, .none)

        case .shareButtonTapped:
            let imageIds = state.parentState.clips.selectedValues()
                .flatMap { $0.items.map { $0.imageId } }
            nextState.alert = .share(imageIds: imageIds, targetCount: nextState.parentState.clips.selectedIds().count)
            return (nextState, .none)

        case .deleteButtonTapped:
            nextState.alert = .deletion(includesRemoveFromAlbum: state.source.isAlbum, targetCount: nextState.parentState.clips.selectedIds().count)
            return (nextState, .none)

        case .mergeButtonTapped:
            return (state, .none)

        // MARK: Alert Completion

        case .alertAddToAlbumConfirmed,
             .alertAddTagsConfirmed,
             .alertHideConfirmed,
             .alertRevealConfirmed,
             .alertRemoveFromAlbumConfirmed,
             .alertDeleteConfirmed,
             .alertDismissed,
             .alertShareConfirmed:
            nextState.alert = nil
            return (nextState, .none)
        }
    }
}

private extension ClipCollectionToolBarState {
    func updatingAppearance() -> Self {
        var nextState = self
        let isEnabled = !parentState.clips.selectedIds().isEmpty

        nextState.isHidden = operation != .selecting
        nextState.items = [
            Item(kind: .add, isEnabled: isEnabled),
            Item(kind: .changeVisibility, isEnabled: isEnabled),
            Item(kind: .share, isEnabled: isEnabled),
            Item(kind: .delete, isEnabled: isEnabled),
            Item(kind: .merge, isEnabled: isEnabled && parentState.clips.selectedIds().count > 1)
        ]

        return nextState
    }
}
