//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

public struct ThumbnailConfig {
    public let cacheKey: String
    public let size: CGSize
    public let scale: CGFloat

    public init(cacheKey: String, size: CGSize, scale: CGFloat) {
        self.cacheKey = cacheKey
        self.size = size
        self.scale = scale
    }
}
