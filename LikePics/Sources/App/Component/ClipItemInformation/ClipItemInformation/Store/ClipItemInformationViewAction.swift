//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit
import Domain
import Foundation

enum ClipItemInformationViewAction: Action {
    // MARK: View Life-Cycle

    case viewWillAppear
    case viewDidAppear
    case viewWillDisappear
    case viewDidLoad

    // MARK: State Observation

    case clipUpdated(Clip)
    case failedToLoadClip

    case clipItemUpdated(ClipItem)
    case failedToLoadClipItem

    case tagsUpdated([Tag])
    case failedToLoadTags

    case albumsUpdated([ListingAlbum])
    case failedToLoadAlbums

    case settingUpdated(isSomeItemsHidden: Bool)
    case failedToLoadSetting

    // MARK: Control

    case tagAdditionButtonTapped
    case albumAdditionButtonTapped
    case tagRemoveButtonTapped(Tag.Identity)
    case siteUrlEditButtonTapped
    case hidedClip
    case revealedClip
    case urlOpenMenuSelected(URL?)
    case urlCopyMenuSelected(URL?)
    case tagTapped(Tag)
    case albumTapped(ListingAlbum)

    // MARK: Modal Completion

    case tagsSelected(Set<Tag.Identity>?)
    case albumSelected(Album.Identity?)
    case modalCompleted(Bool)

    // MARK: Alert Completion

    case siteUrlEditConfirmed(text: String)
    case alertDismissed
}
