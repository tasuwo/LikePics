//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

typealias ClipPreviewPageViewRootDependency = ClipPreviewPageViewDependency
    & ClipPreviewPageBarDependency
    & ClipPreviewPageViewCacheDependency

private typealias RootState = ClipPreviewPageViewRootState
private typealias RootAction = ClipPreviewPageViewRootAction

let clipPreviewPageViewRootReducer = MergeReducer<ClipPreviewPageViewRootState, ClipPreviewPageViewRootAction, ClipPreviewPageViewRootDependency>(
    ClipPreviewPageViewReducer().upstream(RootState.pageConverter,
                                          RootAction.pageConverter,
                                          { $0 as ClipPreviewPageViewDependency }),
    ClipPreviewPageBarReducer().upstream(RootState.barConverter,
                                         RootAction.barConverter,
                                         { $0 as ClipPreviewPageBarDependency }),
    ClipPreviewPageViewCacheReducer().upstream(RootState.cacheConverter,
                                               RootAction.cacheConverter,
                                               { $0 as ClipPreviewPageViewCacheDependency })
)
