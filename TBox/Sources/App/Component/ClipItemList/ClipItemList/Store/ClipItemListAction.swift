//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import ForestKit

enum ClipItemListAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case clipUpdated(Clip)
    case clipDeleted
    case itemsUpdated([ClipItem])
    case tagsUpdated([Tag])
    case settingUpdated(isSomeItemsHidden: Bool)

    // MARK: Operation

    case reordered([ClipItem.Identity])
    case selected(ClipItem.Identity)
    case itemsReorderFailed
    case dismiss

    // MARK: Menu

    case deleteMenuTapped(ClipItem.Identity)
    case openImageUrlMenuTapped(ClipItem.Identity)
    case copyImageUrlMenuTapped(ClipItem.Identity)

    // MARK: Alert Completion

    case alertDeleteConfirmed
    case alertDismissed
}