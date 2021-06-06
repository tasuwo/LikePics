//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipInformationViewCacheState: Equatable {
    var clip: Clip?
    var tags: EntityCollectionSnapshot<Tag>
    var albums: EntityCollectionSnapshot<ListingAlbum>
    var item: ClipItem?
    var isSomeItemsHidden: Bool

    var isInvalidated: Bool
}

extension ClipInformationViewCacheState {
    init(isSomeItemsHidden: Bool) {
        clip = nil
        tags = .init()
        albums = .init()
        item = nil
        self.isSomeItemsHidden = isSomeItemsHidden
        isInvalidated = false
    }
}
