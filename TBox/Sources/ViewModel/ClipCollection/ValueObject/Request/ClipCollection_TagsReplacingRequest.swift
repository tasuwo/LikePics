//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipCollection {
    struct TagsReplacingRequest {
        let target: Clip.Identity
        let tags: Set<Tag.Identity>
    }
}
