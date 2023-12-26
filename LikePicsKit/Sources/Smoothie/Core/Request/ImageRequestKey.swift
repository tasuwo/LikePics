//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

public struct ImageRequestKey: Equatable {
    // MARK: - Properties

    public let cacheKey: String?
    public let size: CGSize?
    public let scale: CGFloat?

    // MARK: - Initializers

    public init(_ request: ImageRequest) {
        self.cacheKey = request.cacheKey
        self.size = request.resize?.size
        self.scale = request.resize?.scale
    }

    public init(cacheKey: String, size: CGSize?, scale: CGFloat?) {
        self.cacheKey = cacheKey
        self.size = size
        self.scale = scale
    }
}

extension ImageRequestKey: Hashable {
    // MARK: - Hashable

    public func hash(into hasher: inout Hasher) {
        hasher.combine(cacheKey)
        hasher.combine(size?.width)
        hasher.combine(size?.height)
        hasher.combine(scale)
    }
}
