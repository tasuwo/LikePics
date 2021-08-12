//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipPreviewPageBarState: Equatable {
    enum Alert: Equatable {
        case addition
        case deletion(includesRemoveFromClip: Bool)
        case share(imageIds: [ImageContainer.Identity])
        case shareTargetSelection
        case error(String)
    }

    struct Item: Equatable {
        enum Kind: Equatable {
            case back
            case list
            case browse
            case add
            case share
            case delete
            case info
        }

        let kind: Kind
        let isEnabled: Bool
    }

    var parentState: ClipPreviewPageViewState
    var isVerticalSizeClassCompact: Bool

    var leftBarButtonItems: [Item]
    var rightBarButtonItems: [Item]
    var toolBarItems: [Item]

    var isFullscreen: Bool
    var isNavigationBarHidden: Bool
    var isToolBarHidden: Bool

    var alert: Alert?
}
