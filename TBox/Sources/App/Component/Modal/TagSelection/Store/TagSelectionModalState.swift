//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import CoreGraphics
import Domain

struct TagSelectionModalState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case addition
    }

    var searchQuery: String
    var searchStorage: SearchableStorage<Tag>
    var tags: Collection<Tag>

    var isCollectionViewHidden: Bool
    var isEmptyMessageViewHidden: Bool
    var isSearchBarEnabled: Bool
    var isSomeItemsHidden: Bool

    var alert: Alert?

    var isDismissed: Bool
}

extension TagSelectionModalState {
    init(selections: Set<Tag.Identity>, isSomeItemsHidden: Bool) {
        searchQuery = ""
        searchStorage = .init()
        tags = .init(selectedIds: selections)

        isCollectionViewHidden = true
        isEmptyMessageViewHidden = true
        isSearchBarEnabled = false
        self.isSomeItemsHidden = isSomeItemsHidden

        alert = nil

        isDismissed = false
    }
}

extension TagSelectionModalState {
    var emptyMessageViewAlpha: CGFloat {
        isEmptyMessageViewHidden ? 0 : 1
    }
}
