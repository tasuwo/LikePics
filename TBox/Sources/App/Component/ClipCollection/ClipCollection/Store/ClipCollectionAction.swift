//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum ClipCollectionAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad
    case viewDidAppear

    // MARK: State Observation

    case clipsUpdated([Clip])
    case settingUpdated(isSomeItemsHidden: Bool)

    // MARK: Selection

    case selected(Clip.Identity)
    case deselected(Clip.Identity)
    case reordered([Clip.Identity])

    // MARK: NavigationBar/ToolBar

    case navigationBarEventOccurred(ClipCollectionNavigationBarEvent)
    case toolBarEventOccurred(ClipCollectionToolBarEvent)

    // MARK: Context Menu

    case tagAdditionMenuTapped(Clip.Identity)
    case albumAdditionMenuTapped(Clip.Identity)
    case hideMenuTapped(Clip.Identity)
    case deferredHide(Clip.Identity)
    case revealMenuTapped(Clip.Identity)
    case editMenuTapped(Clip.Identity)
    case shareMenuTapped(Clip.Identity, IndexPath)
    case purgeMenuTapped(Clip.Identity, IndexPath)
    case deleteMenuTapped(Clip.Identity, IndexPath)
    case removeFromAlbumMenuTapped(Clip.Identity, IndexPath)

    // MARK: Modal Completion

    case tagsSelected(Set<Tag.Identity>?, for: Set<Clip.Identity>)
    case albumsSelected(Album.Identity?, for: Set<Clip.Identity>)
    case modalCompleted(Bool)

    // MARK: Alert Completion

    case alertDeleteConfirmed
    case alertPurgeConfirmed
    case alertShareDismissed(Bool)
    case alertDismissed

    // MARK: Transition

    case failedToLoad
    case albumDeleted
}
