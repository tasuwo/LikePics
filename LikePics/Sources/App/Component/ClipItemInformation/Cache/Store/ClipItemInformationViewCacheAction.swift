//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import ForestKit

enum ClipItemInformationViewCacheAction: Action {
    // MARK: Life-Cycle

    case pageChanged(clipId: Clip.Identity, itemId: ClipItem.Identity)
    case load(clipId: Clip.Identity, itemId: ClipItem.Identity)

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
}
