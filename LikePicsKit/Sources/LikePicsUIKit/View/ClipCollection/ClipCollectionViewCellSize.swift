//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

public struct ClipCollectionViewCellSizeDescription {
    let primaryThumbnailSize: CGSize
    let secondaryThumbnailSize: CGSize?
    let tertiaryThumbnailSize: CGSize?

    var containsSecondaryThumbnailSize: Bool {
        secondaryThumbnailSize != nil
    }

    var containsTertiaryThumbnailSize: Bool {
        tertiaryThumbnailSize != nil
    }

    public init(
        primaryThumbnailSize: CGSize,
        secondaryThumbnailSize: CGSize?,
        tertiaryThumbnailSize: CGSize?
    ) {
        self.primaryThumbnailSize = primaryThumbnailSize
        self.secondaryThumbnailSize = secondaryThumbnailSize
        self.tertiaryThumbnailSize = tertiaryThumbnailSize
    }
}
