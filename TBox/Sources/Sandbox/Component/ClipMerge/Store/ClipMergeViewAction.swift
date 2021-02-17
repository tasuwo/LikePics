//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum ClipMergeViewAction: Action {
    // MARK: - NavigationBar

    case saveButtonTapped

    // MARK: - Button Action

    case tagAdditionButtonTapped
    case tagDeleteButtonTapped(Tag.Identity)

    // MARK: - CollectionView

    case itemReordered([ClipItem])

    // MARK: - Modal Completion

    case tagsSelected(Set<Tag>?)
    case modalCompleted(Bool)

    // MARK: - Alert Completion

    case alertDismissed
}
