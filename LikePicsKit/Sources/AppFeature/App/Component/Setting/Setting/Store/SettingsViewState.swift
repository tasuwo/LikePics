//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct SettingsViewState: Equatable, Codable {
    enum Alert: String, Equatable, Codable {
        case iCloudSettingForceTurnOnConfirmation = "icloud_setting_force_turn_on_confirmation"
        case iCloudSettingForceTurnOffConfirmation = "icloud_setting_force_turn_off_confirmation"
        case iCloudTurnOffConfirmation = "icloud_turn_off_confirmation"
        case clearAllCacheConfirmation = "clear_all_cache_confirmation"
    }

    enum SwitchState: String, Codable {
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

extension SettingsViewState {
    func removingSessionStates() -> Self {
        var state = self
        state.alert = nil
        return state
    }
}
