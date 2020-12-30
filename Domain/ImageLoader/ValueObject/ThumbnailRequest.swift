//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

public struct ThumbnailRequest {
    public let identifier: UUID
    public let cacheKey: String
    public let originalDataRequest: OriginalImageRequest
    public let size: CGSize
    public let scale: CGFloat
    public let userInfo: [AnyHashable: Any]?

    public init(identifier: UUID,
                cacheKey: String,
                originalDataLoadRequest: OriginalImageRequest,
                size: CGSize,
                scale: CGFloat,
                userInfo: [AnyHashable: Any]? = nil)
    {
        self.identifier = identifier
        self.originalDataRequest = originalDataLoadRequest
        self.cacheKey = cacheKey
        self.size = size
        self.scale = scale
        self.userInfo = userInfo
    }
}
