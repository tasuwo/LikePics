//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ForestKit

typealias ClipCollectionViewRootDependency = ClipCollectionDependency
    & ClipCollectionNavigationBarDependency
    & ClipCollectionToolBarDependency

private typealias RootState = ClipCollectionViewRootState
private typealias RootAction = ClipCollectionViewRootAction

let clipCollectionViewRootReducer = MergeReducer<ClipCollectionViewRootState, ClipCollectionViewRootAction, ClipCollectionViewRootDependency>(
    ClipCollectionReducer().upstream(RootState.clipCollectionConverter,
                                     RootAction.clipCollectionConverter,
                                     { $0 as ClipCollectionDependency }),
    ClipCollectionNavigationBarReducer().upstream(RootState.navigationBarConverter,
                                                  RootAction.navigationBarConverter,
                                                  { $0 as ClipCollectionNavigationBarDependency }),
    ClipCollectionToolBarReducer().upstream(RootState.toolBarConverter,
                                            RootAction.toolBarConverter,
                                            { $0 as ClipCollectionToolBarDependency })
)
