//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import ForestKit

typealias ClipItemListNavigationBarDependency = HasNop

struct ClipItemListNavigationBarReducer: Reducer {
    typealias Dependency = ClipItemListNavigationBarDependency
    typealias State = ClipItemListNavigationBarState
    typealias Action = ClipItemListNavigationBarAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        switch action {
        // MARK: - View Life-Cycle

        case .viewDidLoad:
            return (state.updatingAppearance(), [])

        // MARK: - State Observation

        case let .editted(isEditing):
            var nextState = state
            nextState.isEditing = isEditing
            return (nextState.updatingAppearance(), .none)

        case let .updatedSelectionCount(count):
            var nextState = state
            nextState.selectionCount = count
            return (nextState.updatingAppearance(), .none)

        // MARK: - NavigationBar

        case .didTapCancel,
             .didTapResume,
             .didTapSelect:
            return (state, .none)
        }
    }
}

private extension ClipItemListNavigationBarState {
    func updatingAppearance() -> Self {
        var nextState = self

        nextState.leftItems = [.init(kind: .resume, isEnabled: !isEditing)]
        nextState.rightItems = [
            isEditing
                ? .init(kind: .cancel, isEnabled: true)
                : .init(kind: .select, isEnabled: true)
        ]

        return nextState
    }
}
