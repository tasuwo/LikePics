//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import ForestKit

enum TagCollectionViewAction {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case tagsUpdated([Tag])
    case searchQueryChanged(String)
    case settingUpdated(isSomeItemsHidden: Bool)

    // MARK: Selection

    case select(Tag)
    case hide(Tag)

    // MARK: Button Action

    case emptyMessageViewActionButtonTapped
    case tagAdditionButtonTapped
    case uncategorizedTagButtonTapped

    // MARK: Context Menu

    case copyMenuSelected(Tag)
    case hideMenuSelected(Tag)
    case revealMenuSelected(Tag)
    case deleteMenuSelected(Tag)
    case renameMenuSelected(Tag)

    // MARK: Alert Completion

    case alertDeleteConfirmTapped
    case alertSaveButtonTapped(text: String)
    case alertDismissed
}

extension TagCollectionViewAction: Action {}
