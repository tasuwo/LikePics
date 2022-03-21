//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

/// @mockable
public protocol HasCloudAvailabilityService {
    var cloudAvailabilityService: CloudAvailabilityServiceProtocol { get }
}
