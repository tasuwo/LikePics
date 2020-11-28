//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum CurrentCloudAccountResolverError: Error {
    case noAccount
    case restricted
    case couldNotDetermine
    case failedToCheckAccountStatus(Error)
    case failedToFetchAccountId(Error?)
}

public protocol CurrentCloudAccountResolver {
    static func currentCloudAccount(_ completion: @escaping (Result<CloudAccountIdentifier, CurrentCloudAccountResolverError>) -> Void)
}
