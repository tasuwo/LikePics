//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct ThumbnailRequest {
    public let requestId: String
    public let imageRequest: OriginalImageRequest
    public let config: ThumbnailConfig
    public let userInfo: [ThumbnailRequestUserInfo.Key: Any]?

    public init(requestId: String,
                originalImageRequest: OriginalImageRequest,
                config: ThumbnailConfig,
                userInfo: [ThumbnailRequestUserInfo.Key: Any]? = nil)
    {
        self.requestId = requestId
        self.imageRequest = originalImageRequest
        self.config = config
        self.userInfo = userInfo
    }
}
