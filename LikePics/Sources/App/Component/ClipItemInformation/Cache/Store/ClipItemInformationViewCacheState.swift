//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipItemInformationViewCacheState: Equatable {
    struct Information: Equatable {
        var clip: Clip?
        var tags: EntityCollectionSnapshot<Tag>
        var albums: EntityCollectionSnapshot<ListingAlbum>
        var item: ClipItem?
        var isSomeItemsHidden: Bool
    }

    var clipId: Clip.Identity?
    var itemId: ClipItem.Identity?

    var information: Information?

    var isInvalidated: Bool
}

extension ClipItemInformationViewCacheState {
    init() {
        isInvalidated = false
    }
}

extension ClipItemInformationViewCacheState {
    func cleared() -> Self {
        return .init()
    }
}

extension ClipItemInformationViewCacheState.Information {
    init() {
        self.tags = .init()
        self.albums = .init()
        self.isSomeItemsHidden = true
    }
}
