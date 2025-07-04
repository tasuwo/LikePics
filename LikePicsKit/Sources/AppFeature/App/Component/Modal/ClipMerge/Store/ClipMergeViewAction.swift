//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit
import Domain
import Foundation

enum ClipMergeViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: NavigationBar

    case saveButtonTapped
    case cancelButtonTapped

    // MARK: Button Action

    case tagAdditionButtonTapped
    case tagDeleteButtonTapped(Tag.Identity)
    case editedOverwriteSiteUrl(URL?)
    case shouldSaveAsHiddenItem(Bool)
    case siteUrlButtonTapped(URL)

    // MARK: CollectionView

    case itemReordered([ClipItem])

    // MARK: Modal Completion

    case tagsSelected(Set<Tag>?)
    case modalCompleted(Bool)

    // MARK: Alert Completion

    case alertDismissed

    // MARK: Transition

    case didDismissedManually
}
