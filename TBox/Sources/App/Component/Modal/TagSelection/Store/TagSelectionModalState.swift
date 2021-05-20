//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import Domain

struct TagSelectionModalState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case addition
    }

    let id: UUID

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
    init(id: UUID, selections: Set<Tag.Identity>, isSomeItemsHidden: Bool) {
        self.id = id

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
