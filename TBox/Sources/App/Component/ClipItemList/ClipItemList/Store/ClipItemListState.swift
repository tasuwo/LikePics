//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipItemListState: Equatable {
    enum Alert: Equatable {
        case deletion(ClipItem)
        case error(String)
    }

    struct EditingClip: Equatable {
        let id: Clip.Identity
        let dataSize: Int
        let isHidden: Bool
    }

    let id: UUID

    var clip: EditingClip
    var tags: EntityCollectionSnapshot<Tag>
    var items: EntityCollectionSnapshot<ClipItem>
    var isSomeItemsHidden: Bool

    var isEditing: Bool
    var isDismissed: Bool

    var alert: Alert?
}

extension ClipItemListState {
    init(id: UUID, clipId: Clip.Identity, clipItems: [ClipItem], isSomeItemsHidden: Bool) {
        self.id = id
        // 初回は適当な値で埋めておく
        self.clip = .init(id: clipId, dataSize: 0, isHidden: false)
        self.tags = .init()
        self.items = .init(entities: clipItems.indexed(),
                           filteredIds: Set(clipItems.map(\.id)))
        self.isSomeItemsHidden = isSomeItemsHidden
        self.isEditing = false
        self.isDismissed = false
    }
}

extension ClipItemListState {
    var isToolBarHidden: Bool { !isEditing }
}
