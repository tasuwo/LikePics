//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Domain
import Persistence

extension AppStorageKeys {
    enum UserInterfaceStyleKey: AppStorageKey {
        static var defaultValue: UserInterfaceStyle { .unspecified }
        static var key: String { "userInterfaceStyle" }
    }

    var userInterfaceStyle: UserInterfaceStyleKey.Type { UserInterfaceStyleKey.self }
}

extension AppStorageKeys {
    enum CloudSync: AppStorageKey {
        static var defaultValue: Bool { true }
        static var key: String { "isCloudSyncEnabled" }
    }

    var isCloudSyncEnabled: CloudSync.Type { CloudSync.self }
}
