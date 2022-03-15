//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit

typealias ClipCollectionViewRootDependency = ClipCollectionDependency
    & ClipCollectionNavigationBarDependency
    & ClipCollectionToolBarDependency

private typealias RootState = ClipCollectionViewRootState
private typealias RootAction = ClipCollectionViewRootAction

let clipCollectionViewRootReducer = combine(
    contramap(RootAction.clipsMapping, RootState.clipsMapping, { $0 as ClipCollectionViewRootDependency })(ClipCollectionReducer()),
    contramap(RootAction.navigationBarMapping, RootState.navigationBarMapping, { $0 })(ClipCollectionNavigationBarReducer()),
    contramap(RootAction.toolBarMapping, RootState.toolBarMapping, { $0 })(ClipCollectionToolBarReducer())
)
