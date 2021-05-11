//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol CloudAvailabilityServiceProtocol {
    var state: CurrentValueSubject<CloudAvailability?, Never> { get }
}
