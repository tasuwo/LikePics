//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

enum ClipCollectionNavigationBarAction: Action {
    // MARK: - View Life-Cycle

    case viewDidLoad

    // MARK: - State Observation

    case stateChanged(clipCount: Int,
                      selectionCount: Int,
                      operation: ClipCollection.Operation)

    // MARK: - NavigationBar

    case didTapCancel
    case didTapSelectAll
    case didTapDeselectAll
    case didTapSelect
}
