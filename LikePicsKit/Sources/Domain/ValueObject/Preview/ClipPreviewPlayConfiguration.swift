//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ClipPreviewPlayConfiguration: Equatable, Sendable {
    public static let `default`: Self = .init(animation: .default,
                                              order: .default,
                                              range: .default,
                                              loopEnabled: false,
                                              interval: 5)

    public enum Animation: String, Sendable {
        public static let `default`: Self = .forward

        case forward
        case reverse
        case off
    }

    public enum Order: String, Sendable {
        public static let `default`: Self = .forward

        case forward
        case reverse
        case random
    }

    public enum Range: String, Sendable {
        public static let `default`: Self = .overall

        case overall
        case clip
    }

    public let animation: Animation
    public let order: Order
    public let range: Range
    public let loopEnabled: Bool
    public let interval: Int

    // MARK: - Initializers

    public init(animation: Animation, order: Order, range: Range, loopEnabled: Bool, interval: Int) {
        self.animation = animation
        self.order = order
        self.range = range
        self.loopEnabled = loopEnabled
        self.interval = interval
    }
}
