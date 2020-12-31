//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

public struct ThumbnailRequest {
    public struct ThumbnailInfo {
        public let id: String
        public let size: CGSize
        public let scale: CGFloat

        public init(id: String, size: CGSize, scale: CGFloat) {
            self.id = id
            self.size = size
            self.scale = scale
        }
    }

    public let requestId: String
    public let imageRequest: OriginalImageRequest
    public let thumbnailInfo: ThumbnailInfo
    public let isPrefetch: Bool
    public let userInfo: [AnyHashable: Any]?

    public init(requestId: String,
                originalImageRequest: OriginalImageRequest,
                thumbnailInfo: ThumbnailInfo,
                isPrefetch: Bool = false,
                userInfo: [AnyHashable: Any]? = nil)
    {
        self.requestId = requestId
        self.imageRequest = originalImageRequest
        self.thumbnailInfo = thumbnailInfo
        self.isPrefetch = isPrefetch
        self.userInfo = userInfo
    }
}
