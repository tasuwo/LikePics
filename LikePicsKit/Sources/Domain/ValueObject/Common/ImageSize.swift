//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics

// sourcery: AutoDefaultValue, AutoDefaultValueUsePublic
public struct ImageSize: Codable, Equatable, Hashable, Sendable {
    public static let zero = ImageSize(height: 0, width: 0)

    public let height: Double
    public let width: Double

    public var cgSize: CGSize {
        return CGSize(
            width: self.width,
            height: self.height
        )
    }

    public var aspectRatio: CGFloat {
        return self.width / self.height
    }

    // MARK: - Lifecycle

    // sourcery: AutoDefaultValueUseThisInitializer
    public init(height: Double, width: Double) {
        self.height = height
        self.width = width
    }
}
