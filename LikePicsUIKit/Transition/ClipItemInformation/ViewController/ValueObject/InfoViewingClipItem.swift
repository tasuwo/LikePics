//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

public struct InfoViewingClipItem {
    public let clipId: Clip.Identity
    public let itemId: ClipItem.Identity

    var cellIdentity: ClipPreviewPresentableCellIdentifier {
        return .init(clipId: clipId, itemId: itemId)
    }

    // MARK: - Initializers

    public init(clipId: Clip.Identity, itemId: ClipItem.Identity) {
        self.clipId = clipId
        self.itemId = itemId
    }
}
