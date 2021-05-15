//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

enum ClipCollectionViewRootAction: Action {
    case clipCollection(ClipCollectionAction)
    case toolBar(ClipCollectionToolBarAction)
    case navigationBar(ClipCollectionNavigationBarAction)
}

extension ClipCollectionViewRootAction {
    static let clipCollectionConverter: ActionConverter<Self, ClipCollectionAction> = .init {
        switch $0 {
        case let .clipCollection(action):
            return action

        case let .toolBar(action):
            guard let event = action.mapToEvent() else { return nil }
            return .toolBarEventOccurred(event)

        case let .navigationBar(action):
            guard let event = action.mapToEvent() else { return nil }
            return .navigationBarEventOccurred(event)
        }
    } convert: {
        .clipCollection($0)
    }

    static let toolBarConverter: ActionConverter<Self, ClipCollectionToolBarAction> = .init {
        guard case let .toolBar(action) = $0 else { return nil }; return action
    } convert: {
        .toolBar($0)
    }

    static let navigationBarConverter: ActionConverter<Self, ClipCollectionNavigationBarAction> = .init {
        guard case let .navigationBar(action) = $0 else { return nil }; return action
    } convert: {
        .navigationBar($0)
    }
}

private extension ClipCollectionNavigationBarAction {
    func mapToEvent() -> ClipCollectionNavigationBarEvent? {
        switch self {
        case .didTapCancel:
            return .cancel

        case .didTapSelectAll:
            return .selectAll

        case .didTapDeselectAll:
            return .deselectAll

        case .didTapSelect:
            return .select

        case .didTapLayout:
            return .changeLayout

        default:
            return nil
        }
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
