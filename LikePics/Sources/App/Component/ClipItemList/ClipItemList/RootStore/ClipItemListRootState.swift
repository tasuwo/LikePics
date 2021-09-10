//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ForestKit

struct ClipItemListRootState: Equatable {
    var listState: ClipItemListState
    var navigationBarState: ClipItemListNavigationBarState
    var toolBarState: ClipItemListToolBarState
}

extension ClipItemListRootState {
    static let mappingToList: StateMapping<Self, ClipItemListState> = .init(keyPath: \.listState)
    static let mappingToNavigationBar: StateMapping<Self, ClipItemListNavigationBarState> = .init(keyPath: \.navigationBarState)
    static let mappingToToolBar: StateMapping<Self, ClipItemListToolBarState> = .init(keyPath: \.toolBarState)
}
