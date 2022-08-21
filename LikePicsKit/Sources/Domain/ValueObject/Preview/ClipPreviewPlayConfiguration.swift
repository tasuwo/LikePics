//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ClipPreviewPlayConfiguration: Equatable, Codable {
    public static let `default`: Self = .init(animation: .forward,
                                              order: .forward,
                                              range: .overall,
                                              loopEnabled: false,
                                              interval: 5.0)

    public enum Animation: Equatable, Codable {
        case forward
        case reverse
        case off
    }

    public enum Order: Equatable, Codable {
        case forward
        case reverse
        case random
    }

    public enum Range: Equatable, Codable {
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
