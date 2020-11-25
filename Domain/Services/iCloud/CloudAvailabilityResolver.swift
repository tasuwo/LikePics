//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import CloudKit

public protocol CloudAvailabilityResolver {
    static func checkCloudAvailability(_ completion: @escaping (Result<Bool, Error>) -> Void)
}

public enum iCloudAvailabilityResolver: CloudAvailabilityResolver {
    // MARK: - CloudAvailabilityResolver

    public static func checkCloudAvailability(_ completion: @escaping (Result<Bool, Error>) -> Void) {
        CKContainer.default().accountStatus { status, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            switch status {
            case .available:
                completion(.success(true))

            case .couldNotDetermine, .noAccount, .restricted:
                completion(.success(false))

            @unknown default:
                fatalError("Unexpected status")
            }
        }
    }
}
