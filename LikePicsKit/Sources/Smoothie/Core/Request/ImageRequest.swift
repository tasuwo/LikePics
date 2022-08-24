//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

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

    public let source: ImageSource
    public let resize: Resize?
    public var onlyMemoryCaching = false

    // MARK: - Initializers

    public init(source: ImageSource,
                resize: Resize? = nil)
    {
        self.source = source
        self.resize = resize
    }
}
