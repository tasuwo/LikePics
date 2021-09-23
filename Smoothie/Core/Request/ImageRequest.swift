//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

public struct ImageRequest {
    // MARK: - Properties

    public let source: ImageSource
    public let size: CGSize
    public let scale: CGFloat

    // MARK: - Initializers

    public init(source: ImageSource, size: CGSize, scale: CGFloat) {
        self.source = source
        self.size = size
        self.scale = scale
    }
}
