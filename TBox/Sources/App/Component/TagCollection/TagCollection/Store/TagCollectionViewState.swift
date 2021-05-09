//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import CoreGraphics
import Domain

struct TagCollectionViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case edit(tagId: Tag.Identity, name: String)
        case deletion(tagId: Tag.Identity, tagName: String)
        case addition
    }

    var tags: Collection<Tag>
    var searchQuery: String
    var searchStorage: SearchableStorage<Tag>

    var isCollectionViewHidden: Bool
    var isEmptyMessageViewHidden: Bool
    var isSearchBarEnabled: Bool
    var isSomeItemsHidden: Bool

    var alert: Alert?
}

extension TagCollectionViewState {
    init(isSomeItemsHidden: Bool) {
        tags = .init()
        searchQuery = ""
        searchStorage = .init()

        isCollectionViewHidden = true
        isEmptyMessageViewHidden = true
        isSearchBarEnabled = false
        self.isSomeItemsHidden = isSomeItemsHidden

        alert = nil
    }
}

extension TagCollectionViewState {
    var emptyMessageViewAlpha: CGFloat {
        isEmptyMessageViewHidden ? 0 : 1
    }
}
