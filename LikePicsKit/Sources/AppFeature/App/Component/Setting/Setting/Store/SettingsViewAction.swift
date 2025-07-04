//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit
import Domain

enum SettingsViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case itemsVisibilityUpdated(isHidden: Bool)
    case iCloudSyncAvailabilityUpdated(isEnabled: Bool)
    case cloudAvailabilityUpdated(availability: CloudAvailability?)

    // MARK: Control

    case itemsVisibilityChanged(isHidden: Bool)
    case iCloudSyncAvailabilityChanged(isEnabled: Bool)
    case clearAllCache

    // MARK: Alert Completion

    case iCloudForceTurnOffConfirmed
    case iCloudForceTurnOnConfirmed
    case iCloudTurnOffConfirmed
    case clearAllCacheConfirmed
    case alertDismissed
}
