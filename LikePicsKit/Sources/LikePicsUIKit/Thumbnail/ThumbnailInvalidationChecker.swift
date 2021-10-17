//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import UIKit

public enum ThumbnailInvalidationChecker {
    public static func shouldInvalidate(originalImageSizeInPoint: CGSize,
                                        thumbnailSizeInPoint: CGSize,
                                        diskCacheSizeInPixel: CGSize,
                                        displayScale: CGFloat) -> Bool
    {
        if originalImageSizeInPoint.width <= thumbnailSizeInPoint.width,
           originalImageSizeInPoint.height <= thumbnailSizeInPoint.height
        {
            return false
        }

        let thresholdInPoint: CGFloat = 30
        let widthDiff = thumbnailSizeInPoint.width - diskCacheSizeInPixel.width / displayScale
        let heightDiff = thumbnailSizeInPoint.height - diskCacheSizeInPixel.height / displayScale

        let result = widthDiff > thresholdInPoint || heightDiff > thresholdInPoint

        return result
    }
}
