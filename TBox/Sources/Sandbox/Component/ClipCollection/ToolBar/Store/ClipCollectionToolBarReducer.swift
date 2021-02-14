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
        // MARK: - View Life-Cycle

        case .viewDidLoad:
            return (state.updatingAppearance(), [eventEffect])

        // MARK: - State Observation

        case let .stateChanged(selectionCount: selectionCount, operation: operation):
            let newState = state
                .updating(targetCount: selectionCount)
                .updating(operation: operation)
                .updatingAppearance()
            return (newState, [eventEffect])

        // MARK: - ToolBar

        case .addButtonTapped:
            return (state.updating(alert: .addition), [eventEffect])

        case .changeVisibilityButtonTapped:
            return (state.updating(alert: .changeVisibility), [eventEffect])

        case .shareButtonTapped:
            return (state, [eventEffect])

        case .deleteButtonTapped:
            return (state.updating(alert: .deletion(includesRemoveFromAlbum: state.context.isAlbum)), [eventEffect])

        case .mergeButtonTapped:
            return (state, [eventEffect])

        // MARK: - Alert Completion

        case .alertAddToAlbumConfirmed,
             .alertAddTagsConfirmed,
             .alertHideConfirmed,
             .alertRevealConfirmed,
             .alertRemoveFromAlbumConfirmed,
             .alertDeleteConfirmed,
             .alertDismissed:
            return (state.updating(alert: nil), [eventEffect])
        }
    }
}

private extension ClipCollectionToolBarState {
    func updatingAppearance() -> Self {
        let isEnabled = _targetCount > 0
        return self
            .updating(isHidden: _operation != .selecting)
            .updating(items: [
                Item(kind: .add, isEnabled: isEnabled),
                Item(kind: .changeVisibility, isEnabled: isEnabled),
                Item(kind: .share, isEnabled: isEnabled),
                Item(kind: .delete, isEnabled: isEnabled),
                Item(kind: .merge, isEnabled: isEnabled && _targetCount > 1)
            ])
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
