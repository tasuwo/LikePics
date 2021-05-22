//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import ForestKit

enum ClipCollectionToolBarAction: Action, Equatable {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case stateChanged

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
    case alertShareConfirmed(Bool)

    case alertDismissed
}
