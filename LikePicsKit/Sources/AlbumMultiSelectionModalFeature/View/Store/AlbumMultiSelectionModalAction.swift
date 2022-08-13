//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit
import Domain

public enum AlbumMultiSelectionModalAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case albumsUpdated([ListingAlbumTitle])
    case searchQueryChanged(String)
    case settingUpdated(isSomeItemsHidden: Bool)

    // MARK: Button Action

    case selected(Album.Identity)
    case deselected(Album.Identity)
    case emptyMessageViewActionButtonTapped
    case addButtonTapped
    case saveButtonTapped

    // MARK: Alert Completion

    case alertSaveButtonTapped(text: String)
    case alertDismissed

    // MARK: Transition

    case didDismissedManually
}
