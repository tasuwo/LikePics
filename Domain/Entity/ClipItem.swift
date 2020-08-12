//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct ClipItem {
    public let clipUrl: URL
    public let clipIndex: Int
    public let thumbnailImageUrl: URL
    public let largeImageUrl: URL

    // MARK: - Lifecycle

    public init(clipUrl: URL,
                clipIndex: Int,
                thumbnailImageUrl: URL,
                largeImageUrl: URL)
    {
        self.clipUrl = clipUrl
        self.clipIndex = clipIndex
        self.thumbnailImageUrl = thumbnailImageUrl
        self.largeImageUrl = largeImageUrl
    }
}
