//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit
import Domain

struct ClipPreviewPageViewRootState: Equatable {
    var pageViewState: ClipPreviewPageViewState
    var barState: ClipPreviewPageBarState
}

extension ClipPreviewPageViewRootState {
    init(filteredClipIds: Set<Clip.Identity>,
         clips: [Clip],
         query: ClipPreviewPageViewState.Query,
         isSomeItemsHidden: Bool,
         indexPath: ClipCollection.IndexPath)
    {
        pageViewState = ClipPreviewPageViewState(filteredClipIds: filteredClipIds,
                                                 clips: clips,
                                                 query: query,
                                                 isSomeItemsHidden: isSomeItemsHidden,
                                                 indexPath: indexPath)
        barState = ClipPreviewPageBarState()
    }
}

extension ClipPreviewPageViewRootState {
    static let mappingToPage: StateMapping<Self, ClipPreviewPageViewState> = .init(keyPath: \.pageViewState)
    static let mappingToBar: StateMapping<Self, ClipPreviewPageBarState> = .init(keyPath: \.barState)
}
