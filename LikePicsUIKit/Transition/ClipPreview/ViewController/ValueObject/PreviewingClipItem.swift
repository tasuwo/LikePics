//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

public struct PreviewingClipItem {
    public let clipId: Clip.Identity
    public let itemId: ClipItem.Identity
    public let imageSize: ImageSize
    public let isItemPrimary: Bool

    var cellIdentity: ClipPreviewPresentableCellIdentifier {
        return .init(clipId: clipId, itemId: itemId)
    }

    // MARK: - Initializers

    public init(clipId: Clip.Identity, itemId: ClipItem.Identity, imageSize: ImageSize, isItemPrimary: Bool) {
        self.clipId = clipId
        self.itemId = itemId
        self.imageSize = imageSize
        self.isItemPrimary = isItemPrimary
    }
}
