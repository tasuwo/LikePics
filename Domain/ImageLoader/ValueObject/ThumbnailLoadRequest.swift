//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

public struct ThumbnailLoadRequest {
    public let identifier: UUID
    public let cacheKey: String
    public let scale: CGFloat
    public let size: CGSize
    public let dataLoader: OriginalDataLoader

    public init(identifier: UUID,
                cacheKey: String,
                scale: CGFloat,
                size: CGSize,
                dataLoader: OriginalDataLoader)
    {
        self.identifier = identifier
        self.cacheKey = cacheKey
        self.scale = scale
        self.size = size
        self.dataLoader = dataLoader
    }
}
