//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipPreviewPageViewCacheState: Equatable {
    var clipId: Clip.Identity?
    var itemId: ClipItem.Identity?
}
