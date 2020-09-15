//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

public class UserSettingStorage {
    enum Key: String {
        case showHiddenItems = "showHiddenItems"
    }

    private let userDefaults = UserDefaults.standard

    public init() {}
}

extension UserSettingStorage: UserSettingStorageProtocol {
    // MARK: - UserSettingStorageProtocol

    public func set(showHiddenItems: Bool) {
        self.userDefaults.set(showHiddenItems, forKey: Key.showHiddenItems.rawValue)
    }

    public func fetchShowHiddenItems() -> Bool {
        return self.userDefaults.bool(forKey: Key.showHiddenItems.rawValue)
    }
}
