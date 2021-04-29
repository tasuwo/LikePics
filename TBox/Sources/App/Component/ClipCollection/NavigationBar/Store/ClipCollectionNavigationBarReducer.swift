//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

typealias ClipCollectionNavigationBarDependency = HasClipCollectionNavigationBarDelegate

enum ClipCollectionNavigationBarReducer: Reducer {
    typealias Dependency = ClipCollectionNavigationBarDependency
    typealias State = ClipCollectionNavigationBarState
    typealias Action = ClipCollectionNavigationBarAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        let stream = Deferred {
            Future<Action?, Never> { promise in
                if let event = action.mapToEvent() {
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
                               operation: operation):
            nextState.clipCount = clipCount
            nextState.selectionCount = selectionCount
            nextState.operation = operation
            nextState = nextState.updatingAppearance()
            return (nextState, [eventEffect])

        // MARK: - NavigationBar

        case .didTapCancel,
             .didTapSelectAll,
             .didTapDeselectAll,
             .didTapSelect:
            return (state, [eventEffect])
        }
    }
}

private extension ClipCollectionNavigationBarState {
    func updatingAppearance() -> Self {
        var nextState = self

        let isSelectedAll = clipCount <= selectionCount
        let isSelectable = clipCount > 0

        let rightItems: [Item]
        let leftItems: [Item]

        switch operation {
        case .none:
            rightItems = [.init(kind: .select, isEnabled: isSelectable)]
            leftItems = []

        case .selecting:
            rightItems = [.init(kind: .cancel, isEnabled: true)]
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
    func mapToEvent() -> ClipCollectionNavigationBarEvent? {
        switch self {
        case .didTapCancel:
            return .cancel

        case .didTapSelectAll:
            return .selectAll

        case .didTapDeselectAll:
            return .deselectAll

        case .didTapSelect:
            return .select

        default:
            return nil
        }
    }
}
