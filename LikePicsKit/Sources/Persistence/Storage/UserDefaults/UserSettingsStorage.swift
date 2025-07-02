//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain
import Foundation

public class UserSettingsStorage {
    enum Key: String {
        case userInterfaceStyle = "userSettingsUserInterfaceStyle"
        case showHiddenItems = "userSettingsShowHiddenItems"
        case enabledICloudSync = "userSettingsEnabledICloudSync"
        case ignoreCloudUnavailableAlert = "userSettingsIgnoreCloudUnavailableAlert"
    }

    private let appBundle: Bundle
    private lazy var userDefaults: UserDefaults = {
        guard let bundleIdentifier = self.appBundle.bundleIdentifier else {
            fatalError("Failed to resolve bundle identifier")
        }
        guard let userDefaults = UserDefaults(suiteName: "group.\(bundleIdentifier)") else {
            fatalError("Failed to initialize UserDefaults")
        }
        return userDefaults
    }()

    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Persistence.UserSettingStorage")

    // MARK: - Lifecycle

    public init(appBundle: Bundle) {
        self.appBundle = appBundle
        self.userDefaults.register(defaults: [
            Self.Key.userInterfaceStyle.rawValue: UserInterfaceStyle.unspecified.rawValue,
            Self.Key.showHiddenItems.rawValue: false,
            Self.Key.enabledICloudSync.rawValue: true,
            Self.Key.ignoreCloudUnavailableAlert.rawValue: false,
        ])
    }

    // MARK: - Methods

    private func setUserInterfaceStyleNonAtomically(_ userInterfaceStyle: UserInterfaceStyle) {
        guard fetchUserInterfaceStyleNonAtomically() != userInterfaceStyle else { return }
        userDefaults.set(userInterfaceStyle.rawValue, forKey: Key.userInterfaceStyle.rawValue)
    }

    private func setShowHiddenItemsNonAtomically(_ showHiddenItems: Bool) {
        guard fetchShowHiddenItemsNonAtomically() != showHiddenItems else { return }
        userDefaults.set(showHiddenItems, forKey: Key.showHiddenItems.rawValue)
    }

    private func setEnabledICloudSyncNonAtomically(_ enabledICloudSync: Bool) {
        guard fetchEnabledICloudSync() != enabledICloudSync else { return }
        userDefaults.set(enabledICloudSync, forKey: Key.enabledICloudSync.rawValue)
    }

    private func setIgnoreCloudUnavailableAlert(_ ignoreCloudUnavailableAlert: Bool) {
        guard fetchIgnoreCloudUnavailableAlert() != ignoreCloudUnavailableAlert else { return }
        userDefaults.set(ignoreCloudUnavailableAlert, forKey: Key.ignoreCloudUnavailableAlert.rawValue)
    }

    private func fetchUserInterfaceStyleNonAtomically() -> UserInterfaceStyle {
        return UserInterfaceStyle(rawValue: userDefaults.userSettingsUserInterfaceStyle) ?? .unspecified
    }

    private func fetchShowHiddenItemsNonAtomically() -> Bool {
        return userDefaults.userSettingsShowHiddenItems
    }

    private func fetchEnabledICloudSync() -> Bool {
        return userDefaults.userSettingsEnabledICloudSync
    }

    private func fetchIgnoreCloudUnavailableAlert() -> Bool {
        return userDefaults.userSettingsIgnoreCloudUnavailableAlert
    }
}

extension UserDefaults {
    @objc dynamic var userSettingsUserInterfaceStyle: String {
        return string(forKey: UserSettingsStorage.Key.userInterfaceStyle.rawValue) ?? UserInterfaceStyle.unspecified.rawValue
    }

    @objc dynamic var userSettingsShowHiddenItems: Bool {
        return bool(forKey: UserSettingsStorage.Key.showHiddenItems.rawValue)
    }

    @objc dynamic var userSettingsEnabledICloudSync: Bool {
        return bool(forKey: UserSettingsStorage.Key.enabledICloudSync.rawValue)
    }

    @objc dynamic var userSettingsIgnoreCloudUnavailableAlert: Bool {
        return bool(forKey: UserSettingsStorage.Key.ignoreCloudUnavailableAlert.rawValue)
    }
}

extension UserSettingsStorage: UserSettingsStorageProtocol {
    // MARK: - UserSettingsStorageProtocol

    public var userInterfaceStyle: AnyPublisher<UserInterfaceStyle, Never> {
        return
            userDefaults
            .publisher(for: \.userSettingsUserInterfaceStyle)
            .map { UserInterfaceStyle(rawValue: $0) ?? .unspecified }
            .eraseToAnyPublisher()
    }

    public var showHiddenItems: AnyPublisher<Bool, Never> {
        return
            userDefaults
            .publisher(for: \.userSettingsShowHiddenItems)
            .eraseToAnyPublisher()
    }

    public var enabledICloudSync: AnyPublisher<Bool, Never> {
        return
            userDefaults
            .publisher(for: \.userSettingsEnabledICloudSync)
            .eraseToAnyPublisher()
    }

    public var ignoreCloudUnavailableAlert: AnyPublisher<Bool, Never> {
        return
            userDefaults
            .publisher(for: \.userSettingsIgnoreCloudUnavailableAlert)
            .eraseToAnyPublisher()
    }

    public func readUserInterfaceStyle() -> UserInterfaceStyle {
        return fetchUserInterfaceStyleNonAtomically()
    }

    public func readShowHiddenItems() -> Bool {
        return fetchShowHiddenItemsNonAtomically()
    }

    public func readEnabledICloudSync() -> Bool {
        return fetchEnabledICloudSync()
    }

    public func readIgnoreCloudUnavailableAlert() -> Bool {
        return fetchIgnoreCloudUnavailableAlert()
    }

    public func set(userInterfaceStyle: UserInterfaceStyle) {
        queue.sync { setUserInterfaceStyleNonAtomically(userInterfaceStyle) }
    }

    public func set(showHiddenItems: Bool) {
        queue.sync { setShowHiddenItemsNonAtomically(showHiddenItems) }
    }

    public func set(enabledICloudSync: Bool) {
        queue.sync { setEnabledICloudSyncNonAtomically(enabledICloudSync) }
    }

    public func set(ignoreCloudUnavailableAlert: Bool) {
        queue.sync { setIgnoreCloudUnavailableAlert(ignoreCloudUnavailableAlert) }
    }
}
