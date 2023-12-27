//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import Foundation

public struct ImageRequest {
    public struct Resize {
        public let size: CGSize
        public let scale: CGFloat

        public init(size: CGSize, scale: CGFloat) {
            self.size = size
            self.scale = scale
        }
    }

    // MARK: - Properties

    let data: () async -> Data?
    let resize: Resize?
    let cacheKey: String
    let diskCacheInvalidate: ((CGSize) -> Bool)?
    public var ignoreDiskCaching = false

    // MARK: - Initializers

    public init(resize: Resize? = nil, cacheKey: String, diskCacheInvalidate: ((_ pixelSize: CGSize) -> Bool)? = nil, _ data: @escaping () async -> Data?) {
        self.resize = resize
        self.cacheKey = cacheKey
        self.diskCacheInvalidate = diskCacheInvalidate
        self.data = data
    }
}
