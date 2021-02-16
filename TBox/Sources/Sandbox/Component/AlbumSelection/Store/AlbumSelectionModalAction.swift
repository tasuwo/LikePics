//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum AlbumSelectionModalAction: Action {
    // MARK: View Life-Cycle Methods

    case viewDidLoad

    // MARK: State Observation

    case albumsUpdated([Album])
    case searchQueryChanged(String)
    case settingUpdated(isSomeItemsHidden: Bool)

    // MARK: Button Action

    case emptyMessageViewActionButtonTapped
    case addButtonTapped

    // MARK: Alert Completion

    case alertSaveButtonTapped(text: String)
    case alertDismissed
}
