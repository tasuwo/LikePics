//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol CloudAvailabilityStore {
    var state: CurrentValueSubject<CloudAvailability?, Never> { get }
}
