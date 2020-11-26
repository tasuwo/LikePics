//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CloudKit

public typealias CloudAccountIdentifier = String

public enum CloudAvailabilityResolverError: Error {
    case noAccount
    case restricted
    case couldNotDetermine
    case failedToCheckAccountStatus(Error)
    case failedToFetchAccountId(Error?)
}

public protocol CloudAvailabilityResolver {
    static func checkCloudAvailability(_ completion: @escaping (Result<CloudAccountIdentifier, CloudAvailabilityResolverError>) -> Void)
}

public enum iCloudAvailabilityResolver: CloudAvailabilityResolver {
    // MARK: - CloudAvailabilityResolver

    public static func checkCloudAvailability(_ completion: @escaping (Result<CloudAccountIdentifier, CloudAvailabilityResolverError>) -> Void) {
        CKContainer.default().accountStatus { status, error in
            if let error = error {
                completion(.failure(.failedToCheckAccountStatus(error)))
                return
            }

            switch status {
            case .available:
                self.resolveAccountId { result in
                    switch result {
                    case let .success(.some(accountId)):
                        completion(.success(accountId))

                    case .success(.none):
                        completion(.failure(.failedToFetchAccountId(nil)))

                    case let .failure(error):
                        completion(.failure(.failedToFetchAccountId(error)))
                    }
                }

            case .couldNotDetermine:
                completion(.failure(.couldNotDetermine))

            case .noAccount:
                completion(.failure(.noAccount))

            case .restricted:
                completion(.failure(.restricted))

            @unknown default:
                fatalError("Unexpected status")
            }
        }
    }

    private static func resolveAccountId(_ completion: @escaping (Result<String?, Error>) -> Void) {
        CKContainer.default().fetchUserRecordID { id, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let id = id else {
                completion(.success(nil))
                return
            }

            completion(.success("\(id.zoneID.zoneName)-\(id.recordName)"))
        }
    }
}
