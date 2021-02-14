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
            let newState = state
                .updating(clipCount: clipCount)
                .updating(selectionCount: selectionCount)
                .updating(operation: operation)
                .updatingAppearance()
            return (newState, [eventEffect])

        // MARK: - NavigationBar

        case .didTapCancel,
             .didTapSelectAll,
             .didTapDeselectAll,
             .didTapSelect,
             .didTapReorder,
             .didTapDone:
            return (state, [eventEffect])
        }
    }
}

private extension ClipCollectionNavigationBarState {
    func updatingAppearance() -> Self {
        let isSelectedAll = clipCount <= selectionCount
        let isSelectable = clipCount > 0
        let existsClip = clipCount > 1

        let rightItems: [Item]
        let leftItems: [Item]

        switch operation {
        case .none:
            rightItems = [
                context.isAlbum ? .init(kind: .reorder, isEnabled: existsClip) : nil,
                .init(kind: .select, isEnabled: isSelectable)
            ].compactMap { $0 }
            leftItems = []

        case .selecting:
            rightItems = [.init(kind: .cancel, isEnabled: true)]
            leftItems = [
                isSelectedAll
                    ? .init(kind: .deselectAll, isEnabled: true)
                    : .init(kind: .selectAll, isEnabled: true)
            ]

        case .reordering:
            rightItems = [.init(kind: .done, isEnabled: true)]
            leftItems = []
        }

        return self.updating(rightItems: rightItems,
                             leftItems: leftItems)
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

        case .didTapReorder:
            return .reorder

        case .didTapDone:
            return .done

        default:
            return nil
        }
    }
}
