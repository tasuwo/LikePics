//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import Domain
import ImageIO

struct DisplayableImageMeta {
    let imageUrl: URL
    let thumbImageUrl: URL?
    let imageSize: CGSize

    var isValid: Bool {
        return self.imageSize.height != 0 && self.imageSize.width != 0
    }

    // MARK: - Lifecycle

    init(urlSet: WebImageUrlSet) {
        self.imageUrl = urlSet.url
        self.thumbImageUrl = urlSet.lowQualityUrl
        self.imageSize = Self.calcImageSize(of: urlSet)
    }

    // MARK: Privates

    private static func calcImageSize(of imageUrlSet: WebImageUrlSet) -> CGSize {
        let targetUrl = imageUrlSet.lowQualityUrl ?? imageUrlSet.url
        if let imageSource = CGImageSourceCreateWithURL(targetUrl as CFURL, nil) {
            if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary? {
                let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as! CGFloat
                let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as! CGFloat
                return .init(width: pixelWidth, height: pixelHeight)
            }
        }
        return .zero
    }
}
