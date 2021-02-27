//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum ClipMergeViewAction: Action {
    // MARK: - NavigationBar

    case saveButtonTapped
    case cancelButtonTapped

    // MARK: - Button Action

    case tagAdditionButtonTapped
    case tagDeleteButtonTapped(Tag.Identity)

    // MARK: - CollectionView

    case itemReordered([ClipItem])

    // MARK: - Modal Completion

    case tagsSelected(Set<Tag>?)

    // MARK: - Alert Completion

    case alertDismissed

    // MARK: Transition

    case didDismissedManually
}
