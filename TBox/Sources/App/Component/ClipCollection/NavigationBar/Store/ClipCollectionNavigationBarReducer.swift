//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

typealias ClipCollectionNavigationBarDependency = HasClipCollectionNavigationBarDelegate

struct ClipCollectionNavigationBarReducer: Reducer {
    typealias Dependency = ClipCollectionNavigationBarDependency
    typealias State = ClipCollectionNavigationBarState
    typealias Action = ClipCollectionNavigationBarAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        let stream = Deferred {
            Future<Action?, Never> { promise in
                if let event = action.mapToEvent(state: state) {
                    dependency.clipCollectionNavigationBarDelegate?.didTriggered(event)
                }
                promise(.success(nil))
            }
        }
        let eventEffect = Effect(stream)

        switch action {
        // MARK: - View Life-Cycle

        case .viewDidLoad:
            return (state.updatingAppearance(), [eventEffect])

        // MARK: - State Observation

        case let .stateChanged(clipCount: clipCount,
                               selectionCount: selectionCount,
                               layout: layout,
                               operation: operation):
            nextState.clipCount = clipCount
            nextState.selectionCount = selectionCount
            nextState.layout = layout
            nextState.operation = operation
            nextState = nextState.updatingAppearance()
            return (nextState, [eventEffect])

        // MARK: - NavigationBar

        case .didTapCancel,
             .didTapSelectAll,
             .didTapDeselectAll,
             .didTapSelect,
             .didTapLayout:
            return (state, [eventEffect])
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

private extension ClipCollectionNavigationBarAction {
    func mapToEvent(state: ClipCollectionNavigationBarState) -> ClipCollectionNavigationBarEvent? {
        switch self {
        case .didTapCancel:
            return .cancel

        case .didTapSelectAll:
            return .selectAll

        case .didTapDeselectAll:
            return .deselectAll

        case .didTapSelect:
            return .select

        case .didTapLayout:
            return .changeLayout(state.layout.nextLayout)

        default:
            return nil
        }
    }
}

private extension ClipCollection.Layout {
    var nextLayout: Self {
        switch self {
        case .grid:
            return .waterfall

        case .waterfall:
            return .grid
        }
    }

    var toItemKind: ClipCollectionNavigationBarState.Item.Kind.Layout {
        switch self {
        case .grid:
            return .grid

        case .waterfall:
            return .waterFall
        }
    }
}
