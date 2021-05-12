//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct SettingsViewState: Equatable {
    enum Alert: Equatable {
        case iCloudSettingForceTurnOnConfirmation
        case iCloudSettingForceTurnOffConfirmation
        case iCloudTurnOffConfirmation
    }

    enum SwitchState {
        // swiftlint:disable:next identifier_name
        case on
        case off
        case loading
    }

    var cloudAvailability: CloudAvailability?

    var isSomeItemsHidden: Bool
    var isICloudSyncEnabled: Bool
    var isICloudSyncAvailabilitySetting: Bool
    var version: String

    var alert: Alert?
}

extension SettingsViewState {
    init(cloudAvailability: CloudAvailability?, isSomeItemsHidden: Bool, isICloudSyncEnabled: Bool) {
        self.cloudAvailability = cloudAvailability
        self.isSomeItemsHidden = isSomeItemsHidden
        self.isICloudSyncEnabled = isICloudSyncEnabled
        isICloudSyncAvailabilitySetting = false
        version = ""
        alert = nil
    }
}

extension SettingsViewState {
    var isSyncICloudEnabledOn: SwitchState {
        if isICloudSyncAvailabilitySetting { return .loading }
        if isICloudSyncEnabled == true, cloudAvailability?.isAvailable == true {
            return .on
        } else {
            return .off
        }
    }

    var versionText: String? {
        version
    }
}
