//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

typealias ClipCollectionToolBarDependency = HasClipCollectionToolBarDelegate
    & HasImageQueryService

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

        case let .stateChanged(selections: selections, operation: operation):
            nextState._selections = selections
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
            let data = Set(state._selections.values.flatMap({ $0 })).compactMap { imageId in
                try? dependency.imageQueryService.read(having: imageId)
            }
            nextState.alert = .share(data: data)
            return (nextState, [eventEffect])

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
             .alertDismissed,
             .alertShareConfirmed:
            nextState.alert = nil
            return (nextState, [eventEffect])
        }
    }
}

private extension ClipCollectionToolBarState {
    func updatingAppearance() -> Self {
        var nextState = self
        let isEnabled = !_selections.isEmpty

        nextState.isHidden = operation != .selecting
        nextState.items = [
            Item(kind: .add, isEnabled: isEnabled),
            Item(kind: .changeVisibility, isEnabled: isEnabled),
            Item(kind: .share, isEnabled: isEnabled),
            Item(kind: .delete, isEnabled: isEnabled),
            Item(kind: .merge, isEnabled: isEnabled && _selections.count > 1)
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

        case let .alertShareConfirmed(succeeded):
            return .share(succeeded)

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
