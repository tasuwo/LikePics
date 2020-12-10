//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

enum ImageUtility {
    static func calcScale(forSize source: CGSize, toFit destination: CGSize) -> CGFloat {
        let widthScale = destination.width / source.width
        let heightScale = destination.height / source.height
        return min(widthScale, heightScale)
    }

    static func calcDownsamplingSize(forOriginalSize imageSize: CGSize) -> CGSize {
        let screenSize = UIScreen.main.bounds.size
        let rotatedScreenSize = CGSize(width: UIScreen.main.bounds.size.height,
                                       height: UIScreen.main.bounds.size.width)

        let scaleToFitScreen = max(self.calcScale(forSize: imageSize, toFit: screenSize),
                                   self.calcScale(forSize: imageSize, toFit: rotatedScreenSize))
        let targetScale = min(1, scaleToFitScreen)

        return imageSize.scaled(by: targetScale)
    }

    static func downsampledImage(data: Data, to pointSize: CGSize) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }

        let maxDimensionInPixels = max(pointSize.width, pointSize.height)
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary

        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }

        return UIImage(cgImage: downsampledImage)
    }
}

private extension CGSize {
    func scaled(by scale: CGFloat) -> Self {
        return .init(width: self.width * scale, height: self.height * scale)
    }
}
