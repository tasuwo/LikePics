//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct ClipItem {
    public struct Image {
        public let url: URL
        public let size: ImageSize

        public init(url: URL, size: ImageSize) {
            self.url = url
            self.size = size
        }
    }

    public let clipUrl: URL
    public let clipIndex: Int
    public let thumbnail: Image
    public let image: Image

    // MARK: - Lifecycle

    public init(clipUrl: URL, clipIndex: Int, thumbnail: Image, image: Image) {
        self.clipUrl = clipUrl
        self.clipIndex = clipIndex
        self.thumbnail = thumbnail
        self.image = image
    }
}
