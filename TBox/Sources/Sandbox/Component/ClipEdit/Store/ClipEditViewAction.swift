//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum ClipEditViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case clipUpdated(Clip)
    case clipDeleted
    case itemsUpdated([ClipItem])
    case tagsUpdated([Tag])
    case settingUpdated(isSomeItemsHidden: Bool)

    // MARK: NavigationBar

    case doneButtonTapped

    // MARK: Button/Switch Action

    case tagAdditionButtonTapped
    case tagDeletionButtonTapped(Tag.Identity)

    case clipHidesSwitchChanged(isOn: Bool)

    case itemsEditButtonTapped
    case itemsEditCancelButtonTapped
    case itemsSiteUrlsEditButtonTapped
    case itemsReordered([ClipItem.Identity])
    case itemsReorderFailed

    case itemSiteUrlEditButtonTapped(ClipItem.Identity)
    case itemSiteUrlButtonTapped(URL?)
    case itemDeletionActionOccurred(ClipItem.Identity, completion: (Bool) -> Void)
    case itemSelected(ClipItem.Identity)
    case itemDeselected(ClipItem.Identity)

    case clipDeletionButtonTapped

    // MARK: Context Menu

    case siteUrlOpenMenuTapped(ClipItem.Identity)
    case siteUrlCopyMenuTapped(ClipItem.Identity)

    // MARK: Modal Completion

    case tagsSelected(Set<Tag.Identity>?)
    case modalCompleted(Bool)

    // MARK: Alert Completion

    case siteUrlEditConfirmed(text: String)
    case alertDismissed

    // MARK: Transition

    case didDismissedManually
}
