//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

struct ClipCollectionViewRootState: Equatable {
    var clipCollectionState: ClipCollectionState

    // MARK: ClipCollectionNavigationBarState

    var navigationBarRightItems: [ClipCollectionNavigationBarState.Item]
    var navigationBarLeftItems: [ClipCollectionNavigationBarState.Item]

    // MARK: ClipCollectionToolBarState

    var toolBarItems: [ClipCollectionToolBarState.Item]
    var isToolBarHidden: Bool
    var toolBarAlert: ClipCollectionToolBarState.Alert?
}

extension ClipCollectionViewRootState {
    init(source: ClipCollection.Source, isSomeItemsHidden: Bool) {
        clipCollectionState = .init(source: source, isSomeItemsHidden: isSomeItemsHidden)
        navigationBarRightItems = []
        navigationBarLeftItems = []
        toolBarItems = []
        isToolBarHidden = true
        toolBarAlert = nil
    }
}

extension ClipCollectionViewRootState {
    func removingSessionStates() -> Self {
        var state = self
        state.clipCollectionState.clips = state.clipCollectionState.clips
            .updated(entities: [:])
            .updated(filteredIds: .init())
        state.clipCollectionState.alert = nil
        return state
    }
}

extension ClipCollectionViewRootState {
    static let clipCollectionConverter: StateConverter<Self, ClipCollectionState> = .init { parent in
        parent.clipCollectionState
    } merge: { state, parent in
        var nextParent = parent
        nextParent.clipCollectionState = state
        return nextParent
    }

    static let navigationBarConverter: StateConverter<Self, ClipCollectionNavigationBarState> = .init { parent in
        .init(source: parent.clipCollectionState.source,
              layout: parent.clipCollectionState.layout,
              operation: parent.clipCollectionState.operation,
              rightItems: parent.navigationBarRightItems,
              leftItems: parent.navigationBarLeftItems,
              clipCount: parent.clipCollectionState.clips._filteredIds.count,
              selectionCount: parent.clipCollectionState.clips._selectedIds.count)
    } merge: { state, parent in
        var nextParent = parent
        nextParent.navigationBarRightItems = state.rightItems
        nextParent.navigationBarLeftItems = state.leftItems
        return nextParent
    }

    static let toolBarConverter: StateConverter<Self, ClipCollectionToolBarState> = .init { parent in
        .init(source: parent.clipCollectionState.source,
              operation: parent.clipCollectionState.operation,
              items: parent.toolBarItems,
              isHidden: parent.isToolBarHidden,
              parentState: parent.clipCollectionState,
              alert: parent.toolBarAlert)
    } merge: { state, parent in
        var nextParent = parent
        nextParent.toolBarItems = state.items
        nextParent.isToolBarHidden = state.isHidden
        nextParent.toolBarAlert = state.alert
        return nextParent
    }
}

// MARK: - Codable

extension ClipCollectionViewRootState: Codable {}
