//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable unowned_variable_capture

import Combine

public class CloudAvailabilityObserver: CloudAvailabilityStore {
    public enum Context {
        case available(identifier: String)
        case unavailable
        case changedAccount

        var availability: CloudAvailability {
            switch self {
            case .available:
                return .available(.none)

            case .changedAccount:
                return .available(.accountChanged)

            case .unavailable:
                return .unavailable
            }
        }
    }

    private let cloudUsageContextStorage: CloudUsageContextStorageProtocol
    private let cloudAvailabilityResolver: CurrentCloudAccountResolver.Type

    private var cancellableBag: Set<AnyCancellable> = []

    public private(set) var state: CurrentValueSubject<CloudAvailability, Never>

    // MARK: - Lifecycle

    public init(cloudUsageContextStorage: CloudUsageContextStorageProtocol,
                cloudAvailabilityResolver: CurrentCloudAccountResolver.Type)
    {
        self.cloudUsageContextStorage = cloudUsageContextStorage
        self.cloudAvailabilityResolver = cloudAvailabilityResolver

        self.state = .init(.unknown)

        NotificationCenter
            .Publisher(center: .default, name: .CKAccountChanged)
            .flatMap { [unowned self] _ in self.resolveCurrentContext() }
            .sink { [unowned self] context in self.update(by: context) }
            .store(in: &self.cancellableBag)

        self.resolveCurrentContext()
            .sink { [unowned self] context in self.update(by: context) }
            .store(in: &self.cancellableBag)
    }

    // MARK: - Methods

    private func update(by context: Context) {
        if case let .available(identifier: identifier) = context {
            self.cloudUsageContextStorage.set(lastLoggedInCloudAccountId: identifier)
        }
        self.state.send(context.availability)
    }

    private func resolveCurrentContext() -> Future<Context, Never> {
        return Future { promise in
            let lastIdentifier = self.cloudUsageContextStorage.lastLoggedInCloudAccountId
            self.cloudAvailabilityResolver.currentCloudAccount { result in
                switch result {
                case let .success(identifier) where lastIdentifier == identifier || lastIdentifier == nil:
                    promise(.success(.available(identifier: identifier)))

                case .success:
                    promise(.success(.changedAccount))

                default:
                    promise(.success(.unavailable))
                }
            }
        }
    }
}
