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

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Methods

    private func setShowHiddenItemsNonAtomically(_ showHiddenItems: Bool) {
        guard self.fetchShowHiddenItemsNonAtomically() != showHiddenItems else { return }
        self.userDefaults.set(showHiddenItems, forKey: Key.showHiddenItems.rawValue)
    }

    private func fetchShowHiddenItemsNonAtomically() -> Bool {
        return self.userDefaults.userSettingsShowHiddenItems
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

    public func set(showHiddenItems: Bool) {
        self.queue.sync { self.setShowHiddenItemsNonAtomically(showHiddenItems) }
    }
}
