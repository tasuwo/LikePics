//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Combine
import Foundation

public let ClipPreviewPlayConfigurationCustomIntervalMax: Int = 60

/// @mockable
public protocol ClipPreviewPlayConfigurationStorageProtocol {
    var animation: AnyPublisher<ClipPreviewPlayConfiguration.Animation, Never> { get }
    var order: AnyPublisher<ClipPreviewPlayConfiguration.Order, Never> { get }
    var range: AnyPublisher<ClipPreviewPlayConfiguration.Range, Never> { get }
    var loopEnabled: AnyPublisher<Bool, Never> { get }
    var interval: AnyPublisher<Int, Never> { get }
    var customIntervals: AnyPublisher<[Int], Never> { get }

    var clipPreviewPlayConfiguration: AnyPublisher<ClipPreviewPlayConfiguration, Never> { get }

    func fetchAnimation() -> ClipPreviewPlayConfiguration.Animation
    func fetchOrder() -> ClipPreviewPlayConfiguration.Order
    func fetchRange() -> ClipPreviewPlayConfiguration.Range
    func fetchLoopEnabled() -> Bool
    func fetchInterval() -> Int
    func fetchCustomIntervals() -> [Int]

    func fetchClipPreviewPlayConfiguration() -> ClipPreviewPlayConfiguration

    func set(animation: ClipPreviewPlayConfiguration.Animation)
    func set(order: ClipPreviewPlayConfiguration.Order)
    func set(range: ClipPreviewPlayConfiguration.Range)
    func set(loopEnabled: Bool)
    func set(interval: Int)
    func appendCustomInterval(_ interval: Int) -> Bool
    func removeCustomInterval(_ interval: Int) -> Bool
}
