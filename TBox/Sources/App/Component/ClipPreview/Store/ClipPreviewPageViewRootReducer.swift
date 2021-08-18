//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ForestKit

typealias ClipPreviewPageViewRootDependency = ClipPreviewPageViewDependency
    & ClipPreviewPageBarDependency
    & ClipPreviewPageViewCacheDependency

private typealias RootState = ClipPreviewPageViewRootState
private typealias RootAction = ClipPreviewPageViewRootAction

let clipPreviewPageViewRootReducer = combine(
    contramap(RootAction.pageMapping, RootState.mappingToPage, { $0 as ClipPreviewPageViewRootDependency })(ClipPreviewPageViewReducer()),
    contramap(RootAction.barMapping, RootState.mappingToBar, { $0 })(ClipPreviewPageBarReducer()),
    contramap(RootAction.cacheMapping, RootState.cacheMapping, { $0 })(ClipPreviewPageViewCacheReducer())
)
