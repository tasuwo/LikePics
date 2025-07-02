//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit

enum ClipCollectionViewRootAction: Action {
    case clipCollection(ClipCollectionAction)
    case toolBar(ClipCollectionToolBarAction)
    case navigationBar(ClipCollectionNavigationBarAction)
}

extension ClipCollectionViewRootAction {
    static let clipsMapping: ActionMapping<Self, ClipCollectionAction> = .init(
        build: {
            .clipCollection($0)
        },
        get: {
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
        }
    )

    static let toolBarMapping: ActionMapping<Self, ClipCollectionToolBarAction> = .init(
        build: {
            .toolBar($0)
        },
        get: {
            guard case let .toolBar(action) = $0 else { return nil }
            return action
        }
    )

    static let navigationBarMapping: ActionMapping<Self, ClipCollectionNavigationBarAction> = .init(
        build: {
            .navigationBar($0)
        },
        get: {
            guard case let .navigationBar(action) = $0 else { return nil }
            return action
        }
    )
}

extension ClipCollectionNavigationBarAction {
    fileprivate func mapToEvent() -> ClipCollectionNavigationBarEvent? {
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

extension ClipCollectionToolBarAction {
    fileprivate func mapToEvent() -> ClipCollectionToolBarEvent? {
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
