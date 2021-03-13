//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

enum SettingsViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case itemsVisibilityUpdated(isHidden: Bool)
    case iCloudSyncAvailabilityUpdated(isEnabled: Bool)

    // MARK: Control

    case itemsVisibilityChanged(isHidden: Bool)
    case iCloudSyncAvailabilityChanged(isEnabled: Bool)

    // MARK: Alert Completion

    case unavailableICloudTurnOffConfirmed
    case unavailableICloudTurnOnConfirmed
    case iCloudTurnOffConfirmed
    case iCloudTurnOffCancelled
    case alertDismissed
}
