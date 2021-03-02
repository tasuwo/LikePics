//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

typealias ClipCollectionToolBarDependency = HasClipCollectionToolBarDelegate

enum ClipCollectionToolBarReducer: Reducer {
    typealias Dependency = ClipCollectionToolBarDependency
    typealias State = ClipCollectionToolBarState
    typealias Action = ClipCollectionToolBarAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        let stream = Deferred {
            Future<Action?, Never> { promise in
                if let event = action.mapToEvent() {
                    dependency.clipCollectionToolBarDelegate?.didTriggered(event)
                }
                promise(.success(nil))
            }
        }
        let eventEffect = Effect(stream)

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return (state.updatingAppearance(), [eventEffect])

        // MARK: State Observation

        case let .stateChanged(selectionCount: selectionCount, operation: operation):
            nextState._targetCount = selectionCount
            nextState.operation = operation
            nextState = nextState.updatingAppearance()
            return (nextState, [eventEffect])

        // MARK: ToolBar

        case .addButtonTapped:
            nextState.alert = .addition
            return (nextState, [eventEffect])

        case .changeVisibilityButtonTapped:
            nextState.alert = .changeVisibility
            return (nextState, [eventEffect])

        case .shareButtonTapped:
            // TODO:
            return (state, [eventEffect])

        case .deleteButtonTapped:
            nextState.alert = .deletion(includesRemoveFromAlbum: state.source.isAlbum)
            return (nextState, [eventEffect])

        case .mergeButtonTapped:
            return (state, [eventEffect])

        // MARK: Alert Completion

        case .alertAddToAlbumConfirmed,
             .alertAddTagsConfirmed,
             .alertHideConfirmed,
             .alertRevealConfirmed,
             .alertRemoveFromAlbumConfirmed,
             .alertDeleteConfirmed,
             .alertDismissed:
            nextState.alert = nil
            return (nextState, [eventEffect])
        }
    }
}

private extension ClipCollectionToolBarState {
    func updatingAppearance() -> Self {
        var nextState = self
        let isEnabled = _targetCount > 0

        nextState.isHidden = operation != .selecting
        nextState.items = [
            Item(kind: .add, isEnabled: isEnabled),
            Item(kind: .changeVisibility, isEnabled: isEnabled),
            Item(kind: .share, isEnabled: isEnabled),
            Item(kind: .delete, isEnabled: isEnabled),
            Item(kind: .merge, isEnabled: isEnabled && _targetCount > 1)
        ]

        return nextState
    }
}

private extension ClipCollectionToolBarAction {
    func mapToEvent() -> ClipCollectionToolBarEvent? {
        switch self {
        case .alertAddToAlbumConfirmed:
            return .addToAlbum

        case .alertAddTagsConfirmed:
            return .addTags

        case .alertHideConfirmed:
            return .hide

        case .alertRevealConfirmed:
            return .reveal

        case .shareButtonTapped:
            return .share

        case .alertRemoveFromAlbumConfirmed:
            return .removeFromAlbum

        case .alertDeleteConfirmed:
            return .delete

        case .mergeButtonTapped:
            return .merge

        default:
            return nil
        }
    }
}
