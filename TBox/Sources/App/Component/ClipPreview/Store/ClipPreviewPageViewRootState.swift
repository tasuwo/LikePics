//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

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
    init(clipId: Clip.Identity) {
        pageViewState = ClipPreviewPageViewState(clipId: clipId)
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
    static let pageConverter: StateConverter<Self, ClipPreviewPageViewState> = .init { parent in
        parent.pageViewState
    } merge: { state, parent in
        var nextState = parent
        nextState.pageViewState = state
        return nextState
    }

    static let barConverter: StateConverter<Self, ClipPreviewPageBarState> = .init { parent in
        .init(parentState: parent.pageViewState,
              isVerticalSizeClassCompact: parent.isVerticalSizeClassCompact,
              leftBarButtonItems: parent.navigationBarLeftItems,
              rightBarButtonItems: parent.navigationBarRightItems,
              toolBarItems: parent.toolBarItems,
              isFullscreen: parent.isFullscreen,
              isNavigationBarHidden: parent.isNavigationBarHidden,
              isToolBarHidden: parent.isToolBarHidden,
              alert: parent.barAlert)
    } merge: { state, parent in
        var nextState = parent
        nextState.isVerticalSizeClassCompact = state.isVerticalSizeClassCompact
        nextState.navigationBarLeftItems = state.leftBarButtonItems
        nextState.navigationBarRightItems = state.rightBarButtonItems
        nextState.toolBarItems = state.toolBarItems
        nextState.isFullscreen = state.isFullscreen
        nextState.isNavigationBarHidden = state.isNavigationBarHidden
        nextState.isToolBarHidden = state.isToolBarHidden
        nextState.barAlert = state.alert
        return nextState
    }

    static let cacheConverter: StateConverter<Self, ClipPreviewPageViewCacheState> = .init { parent in
        .init(clipId: parent.pageViewState.clipId,
              itemId: parent.pageViewState.currentItem?.id)
    } merge: { _, parent in
        // Read only
        return parent
    }
}
