//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Combine
import Foundation

@propertyWrapper
public struct UserDefaultsStorage<Value> {
    private final class Observer: NSObject {
        private let userDefaults: UserDefaults
        private let key: String
        private let onUpdate: () -> Void

        init(userDefaults: UserDefaults, key: String, onUpdate: @escaping () -> Void) {
            self.userDefaults = userDefaults
            self.key = key
            self.onUpdate = onUpdate
            super.init()

            userDefaults.addObserver(self, forKeyPath: key, context: nil)
        }

        deinit {
            userDefaults.removeObserver(self, forKeyPath: key)
        }

        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
            onUpdate()
        }
    }

    private let key: String
    private let defaultValue: Value
    private let userDefaults: UserDefaults
    private let observer: Observer
    private let publisher: CurrentValueSubject<Value, Never>

    public var wrappedValue: Value {
        get {
            return userDefaults.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            userDefaults.set(newValue, forKey: key)
        }
    }

    public var projectedValue: AnyPublisher<Value, Never> {
        publisher.eraseToAnyPublisher()
    }

    public init(key: String, defaultValue: Value, store: UserDefaults? = nil) {
        self.key = key
        self.defaultValue = defaultValue

        let store = store ?? .standard
        self.userDefaults = store
        store.register(defaults: [key: defaultValue])

        let publisher = CurrentValueSubject<Value, Never>(store.object(forKey: key) as? Value ?? defaultValue)
        self.publisher = publisher
        self.observer = Observer(
            userDefaults: store,
            key: key,
            onUpdate: { [publisher, store, defaultValue] in
                publisher.send(store.object(forKey: key) as? Value ?? defaultValue)
            }
        )
    }
}
