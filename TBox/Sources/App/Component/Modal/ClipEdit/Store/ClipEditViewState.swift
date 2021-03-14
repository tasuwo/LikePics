//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipEditViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case siteUrlEdit(itemIds: Set<ClipItem.Identity>, title: String?)
        case deleteConfirmation(IndexPath)
    }

    struct EditingClip: Equatable {
        let id: Clip.Identity
        let dataSize: Int
        let isHidden: Bool
    }

    var clip: EditingClip
    var tags: Collection<Tag>
    var items: Collection<ClipItem>
    var isSomeItemsHidden: Bool

    var isItemsEditing: Bool

    var alert: Alert?

    var isDismissed: Bool
}

extension ClipEditViewState {
    var isItemDeletionEnabled: Bool { items.displayableValues.count > 1 }
    var canReorderItem: Bool { items.displayableValues.count > 1 && !isItemsEditing }
}
