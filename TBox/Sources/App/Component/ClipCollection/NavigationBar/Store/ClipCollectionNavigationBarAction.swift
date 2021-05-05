//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

enum ClipCollectionNavigationBarAction: Action, Equatable {
    // MARK: - View Life-Cycle

    case viewDidLoad

    // MARK: - State Observation

    case stateChanged(clipCount: Int,
                      selectionCount: Int,
                      layout: ClipCollection.Layout,
                      operation: ClipCollection.Operation)

    // MARK: - NavigationBar

    case didTapCancel
    case didTapSelectAll
    case didTapDeselectAll
    case didTapSelect
    case didTapLayout
}
