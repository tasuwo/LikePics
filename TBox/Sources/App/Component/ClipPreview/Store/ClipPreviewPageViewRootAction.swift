//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ForestKit

enum ClipPreviewPageViewRootAction: Action {
    case page(ClipPreviewPageViewAction)
    case bar(ClipPreviewPageBarAction)
    case cache(ClipPreviewPageViewCacheAction)
}

extension ClipPreviewPageViewRootAction {
    static let pageConverter: ActionConverter<Self, ClipPreviewPageViewAction> = .init {
        switch $0 {
        case let .page(action):
            return action

        case let .bar(action):
            guard let event = action.mapToEvent() else { return nil }
            return .barEventOccurred(event)

        default:
            return nil
        }
    } convert: {
        .page($0)
    }

    static let barConverter: ActionConverter<Self, ClipPreviewPageBarAction> = .init {
        guard case let .bar(action) = $0 else { return nil }; return action
    } convert: {
        .bar($0)
    }

    static let cacheConverter: ActionConverter<Self, ClipPreviewPageViewCacheAction> = .init {
        guard case let .cache(action) = $0 else { return nil }; return action
    } convert: {
        .cache($0)
    }
}

private extension ClipPreviewPageBarAction {
    func mapToEvent() -> ClipPreviewPageBarEvent? {
        switch self {
        case .backButtonTapped:
            return .backed

        case .infoButtonTapped:
            return .infoRequested

        case .browseButtonTapped:
            return .browsed

        case .alertDeleteClipConfirmed:
            return .deleteClip

        case .alertDeleteClipItemConfirmed:
            return .removeFromClip

        case .alertTagAdditionConfirmed:
            return .addTags

        case .alertAlbumAdditionConfirmed:
            return .addToAlbum

        case let .alertShareDismissed(succeeded):
            return .shared(succeeded)

        default:
            return nil
        }
    }
}
