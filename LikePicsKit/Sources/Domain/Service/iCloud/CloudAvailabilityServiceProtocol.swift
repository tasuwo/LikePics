//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol CloudAvailabilityServiceProtocol {
    var availability: AnyPublisher<CloudAvailability?, Never> { get }
}
