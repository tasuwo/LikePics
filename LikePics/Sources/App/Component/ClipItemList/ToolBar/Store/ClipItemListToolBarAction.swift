//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import ForestKit
import Foundation

enum ClipItemListToolBarAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case selected(Set<ClipItem>)

    // MARK: ToolBar

    case editUrlButtonTapped
    case shareButtonTapped
    case deleteButtonTapped

    // MARK: Alert Completion

    case alertDeleteConfirmed
    case alertShareConfirmed(Bool)
    case alertSiteUrlEditted(URL)
    case alertDismissed
}
