//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit

typealias ClipCollectionNavigationBarDependency = HasNop

struct ClipCollectionNavigationBarReducer: Reducer {
    typealias Dependency = ClipCollectionNavigationBarDependency
    typealias State = ClipCollectionNavigationBarState
    typealias Action = ClipCollectionNavigationBarAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: - View Life-Cycle

        case .viewDidLoad:
            return (state.updatingAppearance(), [])

        // MARK: - State Observation

        case .stateChanged:
            nextState = nextState.updatingAppearance()
            return (nextState, .none)

        // MARK: - NavigationBar

        case .didTapCancel,
             .didTapSelectAll,
             .didTapDeselectAll,
             .didTapSelect,
             .didTapLayout:
            return (state, .none)
        }
    }
}

private extension ClipCollectionNavigationBarState {
    func updatingAppearance() -> Self {
        var nextState = self

        let isSelectedAll = clipCount <= selectionCount
        let isSelectable = clipCount > 0
        let nextLayout = layout.nextLayout.toItemKind

        let rightItems: [Item]
        let leftItems: [Item]

        switch operation {
        case .none:
            rightItems = [
                .init(kind: .layout(nextLayout), isEnabled: clipCount > 0),
                .init(kind: .select, isEnabled: isSelectable)
            ]
            leftItems = []

        case .selecting:
            rightItems = [
                .init(kind: .layout(nextLayout), isEnabled: false),
                .init(kind: .cancel, isEnabled: true)
            ]
            leftItems = [
                isSelectedAll
                    ? .init(kind: .deselectAll, isEnabled: true)
                    : .init(kind: .selectAll, isEnabled: true)
            ]
        }

        nextState.rightItems = rightItems
        nextState.leftItems = leftItems

        return nextState
    }
}

private extension ClipCollection.Layout {
    var toItemKind: ClipCollectionNavigationBarState.Item.Kind.Layout {
        switch self {
        case .grid:
            return .grid

        case .waterfall:
            return .waterFall
        }
    }
}
