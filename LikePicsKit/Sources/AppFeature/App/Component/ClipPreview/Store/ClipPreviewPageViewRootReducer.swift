//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit

typealias ClipPreviewPageViewRootDependency = ClipPreviewPageViewDependency
    & ClipPreviewPageBarDependency

private typealias RootState = ClipPreviewPageViewRootState
private typealias RootAction = ClipPreviewPageViewRootAction

let clipPreviewPageViewRootReducer = combine(
    contramap(RootAction.pageMapping, RootState.mappingToPage, { $0 as ClipPreviewPageViewRootDependency })(ClipPreviewPageViewReducer()),
    contramap(RootAction.barMapping, RootState.mappingToBar, { $0 })(ClipPreviewPageBarReducer())
)
