//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CloudKit

public enum CloudAccountService {}

extension CloudAccountService: CloudAccountServiceProtocol {
    // MARK: - CloudAccountServiceProtocol

    public static func resolve(_ completion: @escaping (Result<CloudAccountStatus, Error>) -> Void) {
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

            @unknown default:
                fatalError("Unexpected status")
            }
        }
    }
}
