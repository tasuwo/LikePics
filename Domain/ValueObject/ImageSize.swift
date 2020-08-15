//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct ImageSize: Equatable {
    public static let zero = ImageSize(height: 0, width: 0)

    public let height: Double
    public let width: Double

    // MARK: - Lifecycle

    public init(height: Double, width: Double) {
        self.height = height
        self.width = width
    }
}
