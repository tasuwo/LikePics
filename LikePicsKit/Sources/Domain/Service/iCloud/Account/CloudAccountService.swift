//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CloudKit
import Combine

public class CloudAccountService {
    private let _accountStatus: CurrentValueSubject<CloudAccountStatus?, Error> = .init(nil)
    private var subscriptions: Set<AnyCancellable> = .init()

    // MARK: - Initializers

    public init() {
        updateAccountStatus()

        NotificationCenter
            .Publisher(center: .default, name: .CKAccountChanged)
            .sink { [weak self] _ in self?.updateAccountStatus() }
            .store(in: &self.subscriptions)
    }

    // MARK: - Methods

    private func updateAccountStatus() {
        Self.resolve { [weak self] result in
            switch result {
            case let .success(status):
                self?._accountStatus.send(status)

            case let .failure(error):
                self?._accountStatus.send(completion: .failure(error))
            }
        }
    }

    private static func resolve(_ completion: @escaping (Result<CloudAccountStatus, Error>) -> Void) {
        CKContainer.default().accountStatus { status, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            switch status {
            case .available:
                CKContainer.default().fetchUserRecordID { id, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    guard let id = id else {
                        completion(.success(.noAccount))
                        return
                    }

                    completion(.success(.available(identifier: "\(id.zoneID.zoneName)-\(id.recordName)")))
                }

            case .couldNotDetermine:
                completion(.success(.couldNotDetermine))

            case .noAccount:
                completion(.success(.noAccount))

            case .restricted:
                completion(.success(.restricted))

            case .temporarilyUnavailable:
                completion(.success(.temporaryUnavailable))

            @unknown default:
                completion(.success(.internalError))
            }
        }
    }
}

extension CloudAccountService: CloudAccountServiceProtocol {
    // MARK: - CloudAccountServiceProtocol

    public var accountStatus: AnyPublisher<CloudAccountStatus?, Error> {
        _accountStatus.eraseToAnyPublisher()
    }

    public func currentAccountStatus(_ completion: @escaping (Result<CloudAccountStatus, Error>) -> Void) {
        Self.resolve(completion)
    }
}
