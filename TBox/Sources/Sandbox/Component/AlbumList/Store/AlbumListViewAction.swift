//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum AlbumListViewAction: Action {
    // MARK: View Life-Cycle Methods

    case viewDidLoad

    // MARK: State Observation

    case albumsUpdated([Album])
    case searchQueryChanged(String)
    case settingUpdated(isSomeItemsHidden: Bool)
    case editingChanged(isEditing: Bool)

    // MARK: CollectionView

    case selected(Album.Identity)

    // MARK: NavigationBar

    case addButtonTapped

    // MARK: Button Action

    case removerTapped(Album.Identity, at: IndexPath)
    case editingTitleTapped(Album.Identity)
    case emptyMessageViewActionButtonTapped

    // MARK: Reorder

    case reordered([Album.Identity])

    // MARK: Context Menu

    case renameMenuTapped(Album.Identity)
    case hideMenuTapped(Album.Identity)
    case revealMenuTapped(Album.Identity)
    case deleteMenuTapped(Album.Identity, at: IndexPath)

    case deferredHide(Album.Identity)

    // MARK: Alert Completion

    case alertSaveButtonTapped(text: String)
    case alertDeleteConfirmed
    case alertDismissed
}
