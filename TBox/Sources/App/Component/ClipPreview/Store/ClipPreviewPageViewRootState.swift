//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import ForestKit

struct ClipPreviewPageViewRootState: Equatable {
    var pageViewState: ClipPreviewPageViewState
    var barState: ClipPreviewPageBarState
}

extension ClipPreviewPageViewRootState {
    init(clipId: Clip.Identity, initialItem: ClipItem.Identity?) {
        pageViewState = ClipPreviewPageViewState(clipId: clipId, initialItem: initialItem)
        barState = ClipPreviewPageBarState()
    }
}

extension ClipPreviewPageViewRootState {
    static let mappingToPage: StateMapping<Self, ClipPreviewPageViewState> = .init(keyPath: \.pageViewState)
    static let mappingToBar: StateMapping<Self, ClipPreviewPageBarState> = .init(keyPath: \.barState)
    static let cacheMapping: StateMapping<Self, ClipPreviewPageViewCacheState> = .init(get: {
        .init(clipId: $0.pageViewState.clipId, itemId: $0.pageViewState.currentItem?.id)
    }, set: {
        // Read only
        return $1
    })
}
