//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import Domain

struct FetchedWebImage {
    let lowQualityImageUrl: URL
    let highQualityImageUrl: URL
    let highQualityImageSize: CGSize
    let lowQualityImageSize: CGSize

    var isValid: Bool {
        return self.highQualityImageSize.height != 0
            && self.highQualityImageSize.width != 0
            && self.lowQualityImageSize.height != 0
            && self.lowQualityImageSize.width != 0
    }

    init(webImage: WebImageUrlSet, highQualityImageSize: CGSize, lowQualityImageSize: CGSize) {
        self.lowQualityImageUrl = webImage.lowQuality
        self.highQualityImageUrl = webImage.highQuality
        self.lowQualityImageSize = lowQualityImageSize
        self.highQualityImageSize = highQualityImageSize
    }

    func imageUrl(for quality: ImageQuality) -> URL {
        switch quality {
        case .low:
            return self.lowQualityImageUrl
        case .high:
            return self.highQualityImageUrl
        }
    }

    func imageSize(for quality: ImageQuality) -> CGSize {
        switch quality {
        case .low:
            return self.lowQualityImageSize
        case .high:
            return self.highQualityImageSize
        }
    }
}
