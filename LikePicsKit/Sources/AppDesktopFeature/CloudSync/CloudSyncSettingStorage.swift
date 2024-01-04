//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Persistence
import PersistentStack

final class CloudSyncSettingStorage: CloudKitSyncSettingStorage {
    @UserDefaultsStorage(\.isCloudSyncEnabled) private var isCloudSyncEnabled

    var isCloudKitSyncEnabled: AsyncStream<Bool> {
        AsyncStream { continuation in
            let cancellable = $isCloudSyncEnabled
                .sink { continuation.yield($0) }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
