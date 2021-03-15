//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum ClipInformationViewAction: Action {
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

    case settingUpdated(isSomeItemsHidden: Bool)
    case failedToLoadSetting

    // MARK: Control

    case tagAdditionButtonTapped
    case tagRemoveButtonTapped(Tag.Identity)
    case siteUrlEditButtonTapped
    case hidedClip
    case revealedClip
    case urlOpenMenuSelected(URL?)
    case urlCopyMenuSelected(URL?)

    // MARK: Modal Completion

    case tagsSelected(Set<Tag.Identity>?)
    case modalCompleted(Bool)

    // MARK: Alert Completion

    case siteUrlEditConfirmed(text: String)
    case alertDismissed
}
