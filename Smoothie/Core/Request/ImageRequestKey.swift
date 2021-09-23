//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

public struct ImageRequestKey {
    // MARK: - Properties

    public let cacheKey: String
    public let size: CGSize
    public let scale: CGFloat

    // MARK: - Initializers

    public init(_ request: ImageRequest) {
        self.cacheKey = request.source.cacheKey
        self.size = request.size
        self.scale = request.scale
    }

    public init(cacheKey: String, size: CGSize, scale: CGFloat) {
        self.cacheKey = cacheKey
        self.size = size
        self.scale = scale
    }
}
