//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Common
import Domain

public class UserSettingStorage {
    enum Key: String {
        case showHiddenItems = "showHiddenItems"
    }

    private let userDefaults = UserDefaults.standard
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Persistence.UserSettingStorage")
    private var observers: [WeakContainer<UserSettingsObserver>] = []

    public init() {}
}

extension UserSettingStorage: UserSettingStorageProtocol {
    // MARK: - UserSettingStorageProtocol

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
        self.queue.sync {
            guard self.fetchShowHiddenItems() != showHiddenItems else { return }
            self.userDefaults.set(showHiddenItems, forKey: Key.showHiddenItems.rawValue)
            self.observers.forEach { $0.value?.onUpdated(showHiddenItemsTo: showHiddenItems) }
        }
    }

    public func fetchShowHiddenItems() -> Bool {
        return self.queue.sync {
            return self.userDefaults.bool(forKey: Key.showHiddenItems.rawValue)
        }
    }
}
