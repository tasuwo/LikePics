//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import Domain

struct TagSelectionModalState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case addition
    }

    var searchQuery: String
    var tags: Collection<Tag>

    var isCollectionViewDisplaying: Bool
    var isEmptyMessageViewDisplaying: Bool
    var isSearchBarEnabled: Bool

    var alert: Alert?

    var isDismissed: Bool

    var _isSomeItemsHidden: Bool
    var _searchStorage: SearchableStorage<Tag>
}
