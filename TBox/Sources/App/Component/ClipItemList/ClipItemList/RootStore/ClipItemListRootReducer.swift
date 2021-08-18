//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ForestKit

typealias ClipItemListRootDependency = ClipItemListDependency
    & ClipItemListNavigationBarDependency
    & ClipItemListToolBarDependency

private typealias RootState = ClipItemListRootState
private typealias RootAction = ClipItemListRootAction

let clipItemListRootReducer = combine(
    contramap(RootAction.mappingToList, RootState.mappingToList, { $0 as ClipItemListRootDependency })(ClipItemListReducer()),
    contramap(RootAction.mappingToNavigationBar, RootState.mappingToNavigationBar, { $0 })(ClipItemListNavigationBarReducer()),
    contramap(RootAction.mappingToToolBar, RootState.mappingToToolBar, { $0 })(ClipItemListToolBarReducer())
)
