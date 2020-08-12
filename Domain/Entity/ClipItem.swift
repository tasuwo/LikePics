//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct ClipItem {
    public let clipUrl: URL
    public let clipIndex: Int
    public let thumbnailImageUrl: URL
    public let thumbnailSize: ImageSize
    public let largeImageUrl: URL
    public let largeImageSize: ImageSize

    // MARK: - Lifecycle

    public init(clipUrl: URL,
                clipIndex: Int,
                thumbnailImageUrl: URL,
                thumbnailSize: ImageSize,
                largeImageUrl: URL,
                largeImageSize: ImageSize)
    {
        self.clipUrl = clipUrl
        self.clipIndex = clipIndex
        self.thumbnailImageUrl = thumbnailImageUrl
        self.thumbnailSize = thumbnailSize
        self.largeImageUrl = largeImageUrl
        self.largeImageSize = largeImageSize
    }
}
