//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipInformationViewCacheState: Equatable {
    var clip: Clip?
    var tags: Collection<Tag>
    var item: ClipItem?
    var isSomeItemsHidden: Bool

    var isInvalidated: Bool
}
