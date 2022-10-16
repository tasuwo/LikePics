//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import CloudKit
import Combine
import Domain
import PersistentStack

class CloudAvailabilityService {
    private let _availability: CurrentValueSubject<CloudAvailability?, Never> = .init(nil)
    private let task: Task<Void, Never>

    init() {
        self.task = Task { [_availability] in
            for await status in CKAccountStatus.ps.stream {
                _availability.send(CloudAvailability(status))
            }
        }
    }

    deinit {
        task.cancel()
    }
}

extension CloudAvailabilityService: CloudAvailabilityServiceProtocol {
    var availability: AnyPublisher<CloudAvailability?, Never> { _availability.eraseToAnyPublisher() }
}

private extension CloudAvailability {
    init?(_ status: CKAccountStatus?) {
        guard let status else { return nil }
        switch status {
        case .available:
            self = .available

        default:
            self = .unavailable
        }
    }
}
