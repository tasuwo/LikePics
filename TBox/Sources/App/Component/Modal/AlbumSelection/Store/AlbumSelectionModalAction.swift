//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import ForestKit

enum AlbumSelectionModalAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad
    case viewDidDisappear

    // MARK: State Observation

    case albumsUpdated([Album])
    case searchQueryChanged(String)
    case settingUpdated(isSomeItemsHidden: Bool)

    // MARK: Button Action

    case selected(Album.Identity)
    case emptyMessageViewActionButtonTapped
    case addButtonTapped

    // MARK: Alert Completion

    case alertSaveButtonTapped(text: String)
    case alertDismissed
}
