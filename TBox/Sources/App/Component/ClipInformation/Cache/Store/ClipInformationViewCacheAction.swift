//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum ClipInformationViewCacheAction: Action {
    // MARK: Life-Cycle

    case loaded(Clip.Identity, ClipItem.Identity)

    // MARK: State Observation

    case clipUpdated(Clip)
    case failedToLoadClip

    case clipItemUpdated(ClipItem)
    case failedToLoadClipItem

    case tagsUpdated([Tag])
    case failedToLoadTags

    case settingUpdated(isSomeItemsHidden: Bool)
    case failedToLoadSetting
}
