//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit
import Domain

enum ClipItemListAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case clipUpdated(Clip)
    case clipDeleted
    case itemsUpdated([ClipItem])
    case tagsUpdated([Tag])
    case settingUpdated(isSomeItemsHidden: Bool)

    // MARK: NavigationBar/ToolBar

    case navigationBarEventOccurred(ClipItemListNavigationBarEvent)
    case toolBarEventOccurred(ClipItemListToolBarEvent)

    // MARK: Operation

    case reordered([ClipItem.Identity])
    case selected(ClipItem.Identity)
    case deselected(ClipItem.Identity)
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
