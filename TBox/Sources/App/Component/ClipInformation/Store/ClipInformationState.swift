//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipInformationState: Equatable {
    enum Alert: Equatable {
        case deletion(ClipItem)
        case error(String)
    }

    struct EditingClip: Equatable {
        let id: Clip.Identity
        let dataSize: Int
        let isHidden: Bool
    }

    var clip: EditingClip
    var tags: EntityCollectionSnapshot<Tag>
    var items: EntityCollectionSnapshot<ClipItem>
    var isSomeItemsHidden: Bool

    var isDismissed: Bool

    var alert: Alert?
}

extension ClipInformationState {
    init(clipId: Clip.Identity, isSomeItemsHidden: Bool) {
        // 初回は適当な値で埋めておく
        self.clip = .init(id: clipId, dataSize: 0, isHidden: false)
        self.tags = .init()
        self.items = .init()
        self.isSomeItemsHidden = isSomeItemsHidden
        self.isDismissed = false
    }
}
