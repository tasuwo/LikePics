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

    public let data: () async -> Data?
    public let resize: Resize?
    public let cacheKey: String
    public var ignoreDiskCaching = false

    // MARK: - Initializers

    public init(resize: Resize? = nil, cacheKey: String, _ data: @escaping () async -> Data?) {
        self.data = data
        self.resize = resize
        self.cacheKey = cacheKey
    }
}
