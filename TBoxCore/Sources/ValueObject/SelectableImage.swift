//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import ImageIO

public struct SelectableImage: SelectableImageCellDataSource {
    let url: URL
    let alternativeUrl: URL?
    let height: CGFloat
    let width: CGFloat

    var isValid: Bool {
        return self.height != 0
            && self.width != 0
            && self.height > 10
            && self.width > 10
    }

    // MARK: - Lifecycle

    init?(urlSet: WebImageUrlSet) {
        guard let imageSource = CGImageSourceCreateWithURL(urlSet.url as CFURL, nil) else {
            return nil
        }

        guard
            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary?,
            let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? CGFloat,
            let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? CGFloat
        else {
            return nil
        }

        self.url = urlSet.url
        self.alternativeUrl = urlSet.alternativeUrl
        self.height = pixelHeight
        self.width = pixelWidth
    }
}
