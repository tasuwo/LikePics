//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import ForestKit

enum TagSelectionModalAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad
    case viewDidDisappear

    // MARK: State Observation

    case tagsUpdated([Tag])
    case searchQueryChanged(String)
    case settingUpdated(isSomeItemsHidden: Bool)

    // MARK: Selection

    case selected(Tag.Identity)
    case deselected(Tag.Identity)

    // MARK: Button Action

    case emptyMessageViewActionButtonTapped
    case addButtonTapped
    case saveButtonTapped

    // MARK: Alert Completion

    case alertSaveButtonTapped(text: String)
    case alertDismissed
}
