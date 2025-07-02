//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Foundation

extension UserDefaultsStorage {
    public init<Key>(_ keyPath: KeyPath<AppStorageKeys, Key.Type>, store: UserDefaults? = nil) where Key: AppStorageKey, Key.Value == Value, Value == String {
        let storageKey = AppStorageKeys.shared[keyPath: keyPath]
        self.init(key: storageKey.key, defaultValue: storageKey.defaultValue, store: store)
    }

    public init<Key>(_ keyPath: KeyPath<AppStorageKeys, Key.Type>, store: UserDefaults? = nil) where Key: AppStorageKey, Key.Value == Value, Value: RawRepresentable, Value.RawValue == Int {
        let storageKey = AppStorageKeys.shared[keyPath: keyPath]
        self.init(key: storageKey.key, defaultValue: storageKey.defaultValue, store: store)
    }

    public init<Key>(_ keyPath: KeyPath<AppStorageKeys, Key.Type>, store: UserDefaults? = nil) where Key: AppStorageKey, Key.Value == Value, Value == Data {
        let storageKey = AppStorageKeys.shared[keyPath: keyPath]
        self.init(key: storageKey.key, defaultValue: storageKey.defaultValue, store: store)
    }

    public init<Key>(_ keyPath: KeyPath<AppStorageKeys, Key.Type>, store: UserDefaults? = nil) where Key: AppStorageKey, Key.Value == Value, Value == Int {
        let storageKey = AppStorageKeys.shared[keyPath: keyPath]
        self.init(key: storageKey.key, defaultValue: storageKey.defaultValue, store: store)
    }

    public init<Key>(_ keyPath: KeyPath<AppStorageKeys, Key.Type>, store: UserDefaults? = nil) where Key: AppStorageKey, Key.Value == Value, Value: RawRepresentable, Value.RawValue == String {
        let storageKey = AppStorageKeys.shared[keyPath: keyPath]
        self.init(key: storageKey.key, defaultValue: storageKey.defaultValue, store: store)
    }

    public init<Key>(_ keyPath: KeyPath<AppStorageKeys, Key.Type>, store: UserDefaults? = nil) where Key: AppStorageKey, Key.Value == Value, Value == URL {
        let storageKey = AppStorageKeys.shared[keyPath: keyPath]
        self.init(key: storageKey.key, defaultValue: storageKey.defaultValue, store: store)
    }

    public init<Key>(_ keyPath: KeyPath<AppStorageKeys, Key.Type>, store: UserDefaults? = nil) where Key: AppStorageKey, Key.Value == Value, Value == Double {
        let storageKey = AppStorageKeys.shared[keyPath: keyPath]
        self.init(key: storageKey.key, defaultValue: storageKey.defaultValue, store: store)
    }

    public init<Key>(_ keyPath: KeyPath<AppStorageKeys, Key.Type>, store: UserDefaults? = nil) where Key: AppStorageKey, Key.Value == Value, Value == Bool {
        let storageKey = AppStorageKeys.shared[keyPath: keyPath]
        self.init(key: storageKey.key, defaultValue: storageKey.defaultValue, store: store)
    }
}
