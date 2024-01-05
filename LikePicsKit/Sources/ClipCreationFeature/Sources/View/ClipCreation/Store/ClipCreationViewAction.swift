//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ClipCreationFeatureCore
import CompositeKit
import Domain
import Foundation

enum ClipCreationViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observer

    case imagesLoaded([ClipCreationFeatureCore.ImageSource])
    case imagesSaved
    case failedToLoadImages(ImageSourceResolverError)
    case failedToSaveImages(ClipCreationViewReducer.DownloadError)
    case settingsUpdated(isSomeItemsHidden: Bool)

    // MARK: Control

    case loadImages
    case saveImages
    case editedUrl(URL?)
    case shouldSaveAsHiddenItem(Bool)
    case shouldSaveAsClip(Bool)
    case tapTagAdditionButton
    case tapAlbumAdditionButton
    case tapAlbumDeletionButton(Album.Identity, completion: (Bool) -> Void)
    case tagRemoveButtonTapped(Tag.Identity)
    case selected(UUID)
    case deselected(UUID)

    // MARK: Modal Completion

    case tagsSelected([Tag]?)
    case albumsSelected([ListingAlbumTitle]?)
    case modalCompleted(Bool)

    // MARK: Alert Completion

    case alertDismissed

    // MARK: Dismiss

    case didDismissedManually
}
