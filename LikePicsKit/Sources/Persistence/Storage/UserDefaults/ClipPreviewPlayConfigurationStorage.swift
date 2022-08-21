//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import Foundation

public class ClipPreviewPlayConfigurationStorage {
    enum Key: String {
        case animation = "clipPreviewPlayConfigurationAnimation"
        case order = "clipPreviewPlayConfigurationOrder"
        case range = "clipPreviewPlayConfigurationRange"
        case loopEnabled = "clipPreviewPlayConfigurationLoopEnabled"
        case interval = "clipPreviewPlayConfigurationInterval"
    }

    private let userDefaults = UserDefaults.standard

    // MARK: - Lifecycle

    public init() {
        self.userDefaults.register(defaults: [
            Self.Key.animation.rawValue: ClipPreviewPlayConfiguration.Animation.default.rawValue,
            Self.Key.order.rawValue: ClipPreviewPlayConfiguration.Order.default.rawValue,
            Self.Key.range.rawValue: ClipPreviewPlayConfiguration.Range.default.rawValue,
            Self.Key.loopEnabled.rawValue: ClipPreviewPlayConfiguration.default.loopEnabled,
            Self.Key.interval.rawValue: ClipPreviewPlayConfiguration.default.interval
        ])
    }
}

extension UserDefaults {
    @objc dynamic var clipPreviewPlayConfigurationAnimation: String {
        return string(forKey: ClipPreviewPlayConfigurationStorage.Key.animation.rawValue) ?? ClipPreviewPlayConfiguration.Animation.default.rawValue
    }

    @objc dynamic var clipPreviewPlayConfigurationOrder: String {
        return string(forKey: ClipPreviewPlayConfigurationStorage.Key.order.rawValue) ?? ClipPreviewPlayConfiguration.Order.default.rawValue
    }

    @objc dynamic var clipPreviewPlayConfigurationRange: String {
        return string(forKey: ClipPreviewPlayConfigurationStorage.Key.range.rawValue) ?? ClipPreviewPlayConfiguration.Range.default.rawValue
    }

    @objc dynamic var clipPreviewPlayConfigurationLoopEnabled: Bool {
        return bool(forKey: ClipPreviewPlayConfigurationStorage.Key.loopEnabled.rawValue)
    }

    @objc dynamic var clipPreviewPlayConfigurationInterval: Double {
        return double(forKey: ClipPreviewPlayConfigurationStorage.Key.interval.rawValue)
    }
}

extension ClipPreviewPlayConfigurationStorage: ClipPreviewPlayConfigurationStorageProtocol {
    // MARK: - UserSettingsStorageProtocol

    public var animation: AnyPublisher<Domain.ClipPreviewPlayConfiguration.Animation, Never> {
        return userDefaults
            .publisher(for: \.clipPreviewPlayConfigurationAnimation)
            .map { ClipPreviewPlayConfiguration.Animation(rawValue: $0) ?? ClipPreviewPlayConfiguration.Animation.default }
            .eraseToAnyPublisher()
    }

    public var order: AnyPublisher<Domain.ClipPreviewPlayConfiguration.Order, Never> {
        return userDefaults
            .publisher(for: \.clipPreviewPlayConfigurationOrder)
            .map { ClipPreviewPlayConfiguration.Order(rawValue: $0) ?? ClipPreviewPlayConfiguration.Order.default }
            .eraseToAnyPublisher()
    }

    public var range: AnyPublisher<Domain.ClipPreviewPlayConfiguration.Range, Never> {
        return userDefaults
            .publisher(for: \.clipPreviewPlayConfigurationRange)
            .map { ClipPreviewPlayConfiguration.Range(rawValue: $0) ?? ClipPreviewPlayConfiguration.Range.default }
            .eraseToAnyPublisher()
    }

    public var loopEnabled: AnyPublisher<Bool, Never> {
        return userDefaults
            .publisher(for: \.clipPreviewPlayConfigurationLoopEnabled)
            .eraseToAnyPublisher()
    }

    public var interval: AnyPublisher<TimeInterval, Never> {
        return userDefaults
            .publisher(for: \.clipPreviewPlayConfigurationInterval)
            .eraseToAnyPublisher()
    }

    public var clipPreviewPlayConfiguration: AnyPublisher<Domain.ClipPreviewPlayConfiguration, Never> {
        Publishers
            .CombineLatest4(animation, order, range, loopEnabled)
            .combineLatest(interval)
            .map { args, interval in
                return ClipPreviewPlayConfiguration(animation: args.0,
                                                    order: args.1,
                                                    range: args.2,
                                                    loopEnabled: args.3,
                                                    interval: interval)
            }
            .eraseToAnyPublisher()
    }

    public func fetchAnimation() -> Domain.ClipPreviewPlayConfiguration.Animation {
        return ClipPreviewPlayConfiguration.Animation(rawValue: userDefaults.clipPreviewPlayConfigurationAnimation) ?? .default
    }

    public func fetchOrder() -> Domain.ClipPreviewPlayConfiguration.Order {
        return ClipPreviewPlayConfiguration.Order(rawValue: userDefaults.clipPreviewPlayConfigurationOrder) ?? .default
    }

    public func fetchRange() -> Domain.ClipPreviewPlayConfiguration.Range {
        return ClipPreviewPlayConfiguration.Range(rawValue: userDefaults.clipPreviewPlayConfigurationRange) ?? .default
    }

    public func fetchLoopEnabled() -> Bool {
        return userDefaults.clipPreviewPlayConfigurationLoopEnabled
    }

    public func fetchInterval() -> TimeInterval {
        return userDefaults.clipPreviewPlayConfigurationInterval
    }

    public func fetchClipPreviewPlayConfiguration() -> Domain.ClipPreviewPlayConfiguration {
        return ClipPreviewPlayConfiguration(animation: fetchAnimation(),
                                            order: fetchOrder(),
                                            range: fetchRange(),
                                            loopEnabled: fetchLoopEnabled(),
                                            interval: fetchInterval())
    }

    public func set(animation: Domain.ClipPreviewPlayConfiguration.Animation) {
        userDefaults.set(animation.rawValue, forKey: Key.animation.rawValue)
    }

    public func set(order: Domain.ClipPreviewPlayConfiguration.Order) {
        userDefaults.set(order.rawValue, forKey: Key.order.rawValue)
    }

    public func set(range: Domain.ClipPreviewPlayConfiguration.Range) {
        userDefaults.set(range.rawValue, forKey: Key.range.rawValue)
    }

    public func set(loopEnabled: Bool) {
        userDefaults.set(loopEnabled, forKey: Key.loopEnabled.rawValue)
    }

    public func set(interval: TimeInterval) {
        userDefaults.set(interval, forKey: Key.interval.rawValue)
    }
}
