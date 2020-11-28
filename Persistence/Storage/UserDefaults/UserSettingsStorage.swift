//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

public class UserSettingsStorage {
    enum Key: String {
        case showHiddenItems = "userSettingsShowHiddenItems"
        case enabledICloudSync = "userSettingsEnabledICloudSync"
    }

    private let userDefaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Persistence.UserSettingStorage")

    // MARK: - Lifecycle

    public init() {
        self.userDefaults.register(defaults: [
            Self.Key.showHiddenItems.rawValue: false,
            Self.Key.enabledICloudSync.rawValue: true
        ])
    }

    // MARK: - Methods

    private func setShowHiddenItemsNonAtomically(_ showHiddenItems: Bool) {
        guard self.fetchShowHiddenItemsNonAtomically() != showHiddenItems else { return }
        self.userDefaults.set(showHiddenItems, forKey: Key.showHiddenItems.rawValue)
    }

    private func setEnabledICloudSyncNonAtomically(_ enabledICloudSync: Bool) {
        guard self.fetchEnabledICloudSync() != enabledICloudSync else { return }
        self.userDefaults.set(enabledICloudSync, forKey: Key.enabledICloudSync.rawValue)
    }

    private func fetchShowHiddenItemsNonAtomically() -> Bool {
        return self.userDefaults.userSettingsShowHiddenItems
    }

    private func fetchEnabledICloudSync() -> Bool {
        return self.userDefaults.userSettingsEnabledICloudSync
    }
}

extension UserDefaults {
    @objc dynamic var userSettingsShowHiddenItems: Bool {
        return self.bool(forKey: UserSettingsStorage.Key.showHiddenItems.rawValue)
    }

    @objc dynamic var userSettingsEnabledICloudSync: Bool {
        return self.bool(forKey: UserSettingsStorage.Key.enabledICloudSync.rawValue)
    }
}

extension UserSettingsStorage: UserSettingsStorageProtocol {
    // MARK: - UserSettingsStorageProtocol

    public var showHiddenItems: AnyPublisher<Bool, Never> {
        return self.userDefaults
            .publisher(for: \.userSettingsShowHiddenItems)
            .eraseToAnyPublisher()
    }

    public var enabledICloudSync: AnyPublisher<Bool, Never> {
        return self.userDefaults
            .publisher(for: \.userSettingsEnabledICloudSync)
            .eraseToAnyPublisher()
    }

    public func readShowHiddenItems() -> Bool {
        return self.fetchShowHiddenItemsNonAtomically()
    }

    public func readEnabledICloudSync() -> Bool {
        return self.fetchEnabledICloudSync()
    }

    public func set(showHiddenItems: Bool) {
        self.queue.sync { self.setShowHiddenItemsNonAtomically(showHiddenItems) }
    }

    public func set(enabledICloudSync: Bool) {
        self.queue.sync { self.setEnabledICloudSyncNonAtomically(enabledICloudSync) }
    }
}
