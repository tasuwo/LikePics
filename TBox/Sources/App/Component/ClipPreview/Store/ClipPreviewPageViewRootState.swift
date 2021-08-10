//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import ForestKit

struct ClipPreviewPageViewRootState: Equatable {
    var pageViewState: ClipPreviewPageViewState

    // MARK: ClipPreviewPageBarState

    var isVerticalSizeClassCompact: Bool

    var navigationBarLeftItems: [ClipPreviewPageBarState.Item]
    var navigationBarRightItems: [ClipPreviewPageBarState.Item]
    var toolBarItems: [ClipPreviewPageBarState.Item]

    var isFullscreen: Bool
    var isNavigationBarHidden: Bool
    var isToolBarHidden: Bool

    var barAlert: ClipPreviewPageBarState.Alert?
}

extension ClipPreviewPageViewRootState {
    init(clipId: Clip.Identity, initialItem: ClipItem.Identity?) {
        pageViewState = ClipPreviewPageViewState(clipId: clipId, initialItem: initialItem)
        isVerticalSizeClassCompact = true
        navigationBarLeftItems = []
        navigationBarRightItems = []
        toolBarItems = []
        isFullscreen = false
        isNavigationBarHidden = false
        isToolBarHidden = false
        barAlert = nil
    }
}

extension ClipPreviewPageViewRootState {
    static let pageMapping: StateMapping<Self, ClipPreviewPageViewState> = .init(keyPath: \.pageViewState)

    static let barMapping: StateMapping<Self, ClipPreviewPageBarState> = .init(get: {
        .init(parentState: $0.pageViewState,
              isVerticalSizeClassCompact: $0.isVerticalSizeClassCompact,
              leftBarButtonItems: $0.navigationBarLeftItems,
              rightBarButtonItems: $0.navigationBarRightItems,
              toolBarItems: $0.toolBarItems,
              isFullscreen: $0.isFullscreen,
              isNavigationBarHidden: $0.isNavigationBarHidden,
              isToolBarHidden: $0.isToolBarHidden,
              alert: $0.barAlert)
    }, set: {
        var nextState = $1
        nextState.isVerticalSizeClassCompact = $0.isVerticalSizeClassCompact
        nextState.navigationBarLeftItems = $0.leftBarButtonItems
        nextState.navigationBarRightItems = $0.rightBarButtonItems
        nextState.toolBarItems = $0.toolBarItems
        nextState.isFullscreen = $0.isFullscreen
        nextState.isNavigationBarHidden = $0.isNavigationBarHidden
        nextState.isToolBarHidden = $0.isToolBarHidden
        nextState.barAlert = $0.alert
        return nextState
    })

    static let cacheMapping: StateMapping<Self, ClipPreviewPageViewCacheState> = .init(get: {
        .init(clipId: $0.pageViewState.clipId, itemId: $0.pageViewState.currentItem?.id)
    }, set: {
        // Read only
        return $1
    })
}
