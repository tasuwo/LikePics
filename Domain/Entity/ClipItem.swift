//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public struct ClipItem {
    public let clipUrl: URL
    public let clipIndex: Int
    public let imageUrl: URL
    public let thumbnailImage: UIImage
    public let largeImage: UIImage

    // MARK: - Lifecycle

    public init(clipUrl: URL,
                clipIndex: Int,
                imageUrl: URL,
                thumbnailImage: UIImage,
                largeImage: UIImage)
    {
        self.clipUrl = clipUrl
        self.clipIndex = clipIndex
        self.imageUrl = imageUrl
        self.thumbnailImage = thumbnailImage
        self.largeImage = largeImage
    }
}
