//
//  Copyright ©︎ 2024 Tasuku Tozawa. All rights reserved.
//

public extension AppStorageKeys {
    enum ShowHiddenItems: AppStorageKey {
        public static var defaultValue: Bool { false }
        public static var key: String { "showHidenItems" }
    }

    var showHiddenItems: ShowHiddenItems.Type { ShowHiddenItems.self }
}
