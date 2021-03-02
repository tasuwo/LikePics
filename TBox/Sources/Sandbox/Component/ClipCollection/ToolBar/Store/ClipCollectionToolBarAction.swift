//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

enum ClipCollectionToolBarAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case stateChanged(selectionCount: Int,
                      operation: ClipCollection.Operation)

    // MARK: ToolBar

    case addButtonTapped
    case changeVisibilityButtonTapped
    case shareButtonTapped
    case deleteButtonTapped
    case mergeButtonTapped

    // MARK: Alert Completion

    case alertAddToAlbumConfirmed
    case alertAddTagsConfirmed

    case alertHideConfirmed
    case alertRevealConfirmed

    case alertRemoveFromAlbumConfirmed
    case alertDeleteConfirmed

    case alertDismissed
}
