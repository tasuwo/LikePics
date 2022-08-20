//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ClipPreviewPlayConfiguration: Equatable, Codable {
    public static let `default`: Self = .init(transition: .forward,
                                              order: .forward,
                                              range: .overall,
                                              isLoopOn: false,
                                              interval: 5.0)

    public enum Transition: Equatable, Codable {
        case forward
        case reverse
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

    public let transition: Transition
    public let order: Order
    public let range: Range
    public let isLoopOn: Bool
    public let interval: TimeInterval

    // MARK: - Initializers

    public init(transition: Transition, order: Order, range: Range, isLoopOn: Bool, interval: TimeInterval) {
        self.transition = transition
        self.order = order
        self.range = range
        self.isLoopOn = isLoopOn
        self.interval = interval
    }
}
