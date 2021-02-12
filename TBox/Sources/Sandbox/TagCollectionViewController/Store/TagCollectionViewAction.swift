//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum TagCollectionViewAction {
    case viewDidLoad

    case tagsUpdated([Tag])
    case searchQueryChanged(String)
    case settingUpdated(isHiddenItemEnabled: Bool)

    case select(Tag)
    case hide(Tag)

    case emptyMessageViewActionButtonTapped
    case tagAdditionButtonTapped
    case uncategorizedTagButtonTapped

    case copyMenuSelected(Tag)
    case hideMenuSelected(Tag)
    case revealMenuSelected(Tag)
    case deleteMenuSelected(Tag, IndexPath)
    case renameMenuSelected(Tag)

    case alertDeleteConfirmTapped
    case alertSaveButtonTapped(text: String)
    case alertDismissed
}

extension TagCollectionViewAction: Action {}
