//
//  Copyright ©︎ 2023 Tasuku Tozawa. All rights reserved.
//

import Persistence
import SwiftUI

class CloudSyncSettingCoordinator: ObservableObject {
    @Published var isCloudSyncTurnOffConfirmationPresenting = false
    @Published var isCloudSyncAlwaysTurnOffConfirmationPresenting = false
    @Published var isCloudSyncAlwaysTurnOnConfirmationPresenting = false

    @UserDefaultsStorage(\.isCloudSyncEnabled) private var isCloudSyncEnabled

    private let cloudSyncAvailability: CloudSyncAvailability

    init(cloudSyncAvailability: CloudSyncAvailability) {
        self.cloudSyncAvailability = cloudSyncAvailability
    }

    func wantsToSetCloudSync(to toEnabled: Bool) {
        // iCloudが利用不可な場合は、内部状態を書き換えるか確認する
        if toEnabled, cloudSyncAvailability.isAvailable != true {
            if isCloudSyncEnabled {
                isCloudSyncAlwaysTurnOffConfirmationPresenting = true
            } else {
                isCloudSyncAlwaysTurnOnConfirmationPresenting = true
            }
            return
        }

        if toEnabled {
            isCloudSyncEnabled = true
        } else {
            isCloudSyncTurnOffConfirmationPresenting = true
        }
    }

    func dismissAlert() {
        isCloudSyncTurnOffConfirmationPresenting = false
        isCloudSyncAlwaysTurnOffConfirmationPresenting = false
        isCloudSyncAlwaysTurnOnConfirmationPresenting = false
    }
}
