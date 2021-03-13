//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import Domain

struct TagCollectionViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case edit(tagId: Tag.Identity, name: String)
        case deletion(tagId: Tag.Identity, tagName: String, at: IndexPath)
        case addition
    }

    var tags: Collection<Tag>
    var searchQuery: String

    var isCollectionViewDisplaying: Bool
    var isEmptyMessageViewDisplaying: Bool
    var isSearchBarEnabled: Bool

    var alert: Alert?

    var _isSomeItemsHidden: Bool
    var _searchStorage: SearchableStorage<Tag>
}
