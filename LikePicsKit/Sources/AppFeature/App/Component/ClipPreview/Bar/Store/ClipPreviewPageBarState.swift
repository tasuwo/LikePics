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
            case option
        }

        let kind: Kind
        let isEnabled: Bool
    }

    enum OptionMenuItem: Equatable {
        case info
        case play
        case playConfig
    }

    var isVerticalSizeClassCompact: Bool

    var leftBarButtonItems: [Item]
    var rightBarButtonItems: [Item]
    var toolBarItems: [Item]
    var optionMenuItems: [OptionMenuItem]

    var isFullscreen: Bool
    var isNavigationBarHidden: Bool
    var isToolBarHidden: Bool
    var isPageCounterHidden: Bool

    var alert: Alert?

    var currentIndex: Int?
    var clipItems: [ClipItem]
}

extension ClipPreviewPageBarState {
    init() {
        isVerticalSizeClassCompact = true
        leftBarButtonItems = []
        rightBarButtonItems = []
        toolBarItems = []
        optionMenuItems = []
        isFullscreen = false
        isNavigationBarHidden = false
        isToolBarHidden = false
        isPageCounterHidden = false
        alert = nil
        currentIndex = nil
        clipItems = []
    }
}

extension ClipPreviewPageBarState {
    var pageCount: String? {
        guard let index = currentIndex else { return nil }
        return "\(index + 1)/\(clipItems.count)"
    }
}
