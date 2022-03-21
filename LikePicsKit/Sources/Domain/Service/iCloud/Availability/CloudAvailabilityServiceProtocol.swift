//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol CloudAvailabilityServiceProtocol {
    var availability: AnyPublisher<CloudAvailability?, Error> { get }
    func currentAvailability(_ completion: @escaping (Result<CloudAvailability, Error>) -> Void)
}
