//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import ForestKit

enum ClipCreationViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observer

    case imagesLoaded([ImageLoadSource])
    case imagesSaved
    case failedToLoadImages(ImageLoadSourceResolverError)
    case failedToSaveImages(ClipCreationViewReducer.DownloadError)
    case settingsUpdated(isSomeItemsHidden: Bool)

    // MARK: Control

    case loadImages
    case saveImages
    case editedUrl(URL?)
    case shouldSaveAsHiddenItem(Bool)
    case shouldSaveAsClip(Bool)
    case tagRemoveButtonTapped(Tag.Identity)
    case selected(UUID)
    case deselected(UUID)

    // MARK: Modal Completion

    case tagsSelected([Tag]?)
    case modalCompleted(Bool)

    // MARK: Alert Completion

    case alertDismissed
}
