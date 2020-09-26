//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine
import Common
import Domain

public class UserSettingsStorage {
    enum Key: String {
        case showHiddenItems = "userSettingsShowHiddenItems"
    }

    private let userDefaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Persistence.UserSettingStorage")
    private var observers: [WeakContainer<UserSettingsObserver>] = []

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Methods

    private func setShowHiddenItemsNonAtomically(_ showHiddenItems: Bool) {
        guard self.fetchShowHiddenItemsNonAtomically() != showHiddenItems else { return }
        self.userDefaults.set(showHiddenItems, forKey: Key.showHiddenItems.rawValue)
        self.notify(self.fetchUserSettingsNonAtomically())
    }

    private func fetchShowHiddenItemsNonAtomically() -> Bool {
        return self.userDefaults.userSettingsShowHiddenItems
    }

    private func fetchUserSettingsNonAtomically() -> UserSettings {
        return UserSettings(showHiddenItems: self.fetchShowHiddenItemsNonAtomically())
    }

    private func notify(_ settings: UserSettings) {
        DispatchQueue.global().async {
            self.observers.forEach { $0.value?.onUpdated(to: settings) }
        }
    }
}

extension UserDefaults {
    @objc dynamic var userSettingsShowHiddenItems: Bool {
        return self.bool(forKey: UserSettingsStorage.Key.showHiddenItems.rawValue)
    }
}

extension UserSettingsStorage: UserSettingsStorageProtocol {
    // MARK: - UserSettingsStorageProtocol

    public var showHiddenItems: AnyPublisher<Bool, Never> {
        return self.userDefaults
            .publisher(for: \.userSettingsShowHiddenItems)
            .eraseToAnyPublisher()
    }

    public func add(observer: UserSettingsObserver) {
        self.queue.sync {
            self.observers.append(WeakContainer(value: observer))
        }
    }

    public func remove(observer: UserSettingsObserver) {
        self.queue.sync {
            self.observers.removeAll(where: { $0.value === observer })
            self.observers.removeAll(where: { $0.value == nil })
        }
    }

    public func set(showHiddenItems: Bool) {
        self.queue.sync { self.setShowHiddenItemsNonAtomically(showHiddenItems) }
    }

    public func fetch() -> UserSettings {
        return self.queue.sync { return self.fetchUserSettingsNonAtomically() }
    }
}
