//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable unowned_variable_capture

import Combine

public class CloudAvailabilityService {
    private var _availability: CurrentValueSubject<CloudAvailability?, Error> = .init(nil)

    private let cloudUsageContextStorage: CloudUsageContextStorageProtocol
    private let cloudAccountService: CloudAccountServiceProtocol
    private let queue = DispatchQueue(label: "net.tasuwo.TBox.Domain.CloudAvailabilityService")

    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Lifecycle

    public init(cloudUsageContextStorage: CloudUsageContextStorageProtocol,
                cloudAccountService: CloudAccountServiceProtocol)
    {
        self.cloudUsageContextStorage = cloudUsageContextStorage
        self.cloudAccountService = cloudAccountService

        bind()
    }

    // MARK: - Methods

    private func bind() {
        cloudAccountService.accountStatus
            .compactMap { $0 }
            .receive(on: queue)
            .sink(receiveCompletion: { [weak self] completion in
                self?._availability.send(completion: completion)
            }, receiveValue: { [weak self] status in
                guard let self = self else { return }
                self._availability.send(self.convertAndUpdateLoginStatus(status))
            })
            .store(in: &subscriptions)
    }

    private func convertAndUpdateLoginStatus(_ status: CloudAccountStatus) -> CloudAvailability {
        let lastIdentifier = cloudUsageContextStorage.lastLoggedInCloudAccountId

        switch status {
        case let .available(identifier: id):
            cloudUsageContextStorage.set(lastLoggedInCloudAccountId: id)

            if lastIdentifier == nil || lastIdentifier == id {
                return .available(.none)
            } else {
                return .available(.accountChanged)
            }

        case .couldNotDetermine, .noAccount, .restricted:
            return .unavailable
        }
    }
}

extension CloudAvailabilityService: CloudAvailabilityServiceProtocol {
    public var availability: AnyPublisher<CloudAvailability?, Error> {
        _availability.eraseToAnyPublisher()
    }

    public func currentAvailability(_ completion: @escaping (Result<CloudAvailability, Error>) -> Void) {
        cloudAccountService.currentAccountStatus { [unowned self] result in
            switch result {
            case let .success(status):
                completion(.success(self.convertAndUpdateLoginStatus(status)))

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
