//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

struct SettingsViewState: Equatable {
    enum Alert: Equatable {
        case unavailableICloudTurnOnConfirmation
        case unavailableICloudTurnOffConfirmation
        case iCloudTurnOffConfirmation
    }

    var isSomeItemsHidden: Bool
    var isICloudSyncEnabled: Bool
    var version: String

    var alert: Alert?
}
