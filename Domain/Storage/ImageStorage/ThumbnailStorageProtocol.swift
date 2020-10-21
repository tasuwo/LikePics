//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

/// @mockable
public protocol ThumbnailStorageProtocol {
    /**
     * Clear all cache
     *
     * - attention: for DEBUG
     */
    func clearCache()
    func readThumbnailIfExists(for item: ClipItem) -> UIImage?
    func requestThumbnail(for item: ClipItem, completion: @escaping (UIImage?) -> Void)
    func deleteThumbnailCacheIfExists(for item: ClipItem)
}

extension ThumbnailStorageProtocol {
    public static func calcDownsamplingSize(for item: ClipItem) -> CGSize {
        let imageSize = item.imageSize

        let screenSize = UIScreen.main.bounds.size
        let rotatedScreenSize = CGSize(width: UIScreen.main.bounds.size.height,
                                       height: UIScreen.main.bounds.size.width)

        let scaleToFitScreen = max(self.calcScale(forSize: imageSize.cgSize, toFit: screenSize),
                                   self.calcScale(forSize: imageSize.cgSize, toFit: rotatedScreenSize))
        let targetScale = min(1, scaleToFitScreen)

        return imageSize.cgSize.scaled(by: targetScale)
    }

    public static func calcScale(forSize source: CGSize, toFit destination: CGSize) -> CGFloat {
        let widthScale = destination.width / source.width
        let heightScale = destination.height / source.height
        return min(widthScale, heightScale)
    }
}

private extension CGSize {
    func scaled(by scale: CGFloat) -> Self {
        return .init(width: self.width * scale, height: self.height * scale)
    }
}
