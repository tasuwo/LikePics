//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

extension DependencyContainer: CloudStack {
    // MARK: - CloudStack

    var isCloudSyncEnabled: Bool {
        return self._isCloudSyncEnabled
    }

    func reload(isCloudSyncEnabled: Bool) {
        self._isCloudSyncEnabled = isCloudSyncEnabled
        // TODO:
        try? self.setupCoreDataStack(iCloudSyncEnabled: isCloudSyncEnabled, isInitial: false)
    }
}
