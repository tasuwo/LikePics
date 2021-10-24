//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit

enum ClipPreviewPageViewRootAction: Action {
    case page(ClipPreviewPageViewAction)
    case bar(ClipPreviewPageBarAction)
}

extension ClipPreviewPageViewRootAction {
    static let pageMapping: ActionMapping<Self, ClipPreviewPageViewAction> = .init(build: {
        .page($0)
    }, get: {
        switch $0 {
        case let .page(action):
            return action

        case let .bar(action):
            guard let event = action.mapToEvent() else { return nil }
            return .barEventOccurred(event)
        }
    })

    static let barMapping: ActionMapping<Self, ClipPreviewPageBarAction> = .init(build: {
        .bar($0)
    }, get: {
        guard case let .bar(action) = $0 else { return nil }; return action
    })
}

private extension ClipPreviewPageBarAction {
    func mapToEvent() -> ClipPreviewPageBarEvent? {
        switch self {
        case .backButtonTapped:
            return .backed

        case .listButtonTapped:
            return .listed

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
