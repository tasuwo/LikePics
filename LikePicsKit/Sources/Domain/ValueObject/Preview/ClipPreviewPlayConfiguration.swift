//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ClipPreviewPlayConfiguration: Equatable {
    public static let `default`: Self = .init(animation: .default,
                                              order: .default,
                                              range: .default,
                                              loopEnabled: false,
                                              interval: 5.0)

    public enum Animation: String {
        public static let `default`: Self = .forward

        case forward
        case reverse
        case off
    }

    public enum Order: String {
        public static let `default`: Self = .forward

        case forward
        case reverse
        case random
    }

    public enum Range: String {
        public static let `default`: Self = .overall

        case overall
        case clip
    }

    public let animation: Animation
    public let order: Order
    public let range: Range
    public let loopEnabled: Bool
    public let interval: TimeInterval

    // MARK: - Initializers

    public init(animation: Animation, order: Order, range: Range, loopEnabled: Bool, interval: TimeInterval) {
        self.animation = animation
        self.order = order
        self.range = range
        self.loopEnabled = loopEnabled
        self.interval = interval
    }
}
