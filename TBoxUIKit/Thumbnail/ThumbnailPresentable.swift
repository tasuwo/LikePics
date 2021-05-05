//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import UIKit

public protocol ThumbnailPresentable {
    func calcThumbnailPointSize(originalPixelSize: CGSize?) -> CGSize
}

extension ThumbnailPresentable {
    func shouldInvalidate(thumbnail: UIImage,
                          originalImageSize: CGSize?,
                          displayScale: CGFloat) -> Bool
    {
        guard let originalImageSize = originalImageSize else { return false }

        let actualPixelSize = CGSize(width: thumbnail.size.width * thumbnail.scale,
                                     height: thumbnail.size.height * thumbnail.scale)

        let pointSize = calcThumbnailPointSize(originalPixelSize: originalImageSize)
        let expectedPixelSize = CGSize(width: pointSize.width * displayScale,
                                       height: pointSize.height * displayScale)

        if originalImageSize.width <= expectedPixelSize.width,
           originalImageSize.height <= expectedPixelSize.height
        {
            return false
        }

        let thresholdInPoint: CGFloat = 50
        let thresholdInPixel: CGFloat = thresholdInPoint * displayScale

        let widthPixelDiff = expectedPixelSize.width - actualPixelSize.width
        let heightPixelDiff = expectedPixelSize.height - actualPixelSize.height

        return widthPixelDiff > thresholdInPixel || heightPixelDiff > thresholdInPixel
    }
}
