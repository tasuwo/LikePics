//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipEditViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case siteUrlEdit(itemIds: Set<ClipItem.Identity>, title: String?)
        case deleteConfirmation
    }

    enum Modal: Equatable {
        case tagSelection(tagIds: Set<Tag.Identity>)
    }

    struct EditingClip: Equatable {
        let id: Clip.Identity
        let dataSize: Int
        let isHidden: Bool
    }

    let id: UUID

    var clip: EditingClip
    var tags: Collection<Tag>
    var items: Collection<ClipItem>
    var isSomeItemsHidden: Bool

    var isItemsEditing: Bool

    var alert: Alert?
    var modal: Modal?

    var isDismissed: Bool
}

extension ClipEditViewState {
    init(id: UUID, clipId: Clip.Identity, isSomeItemsHidden: Bool) {
        self.id = id
        // 初回は適当な値で埋めておく
        clip = .init(id: clipId, dataSize: 0, isHidden: false)
        tags = .init()
        items = .init()
        self.isSomeItemsHidden = isSomeItemsHidden

        isItemsEditing = false

        alert = nil

        isDismissed = false
    }
}

extension ClipEditViewState {
    var isItemDeletionEnabled: Bool { items.filteredValues().count > 1 }
    var canReorderItem: Bool { items.filteredValues().count > 1 && !isItemsEditing }
}
