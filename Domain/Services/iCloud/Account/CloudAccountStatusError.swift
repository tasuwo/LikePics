//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public enum CloudAccountStatusError: Error {
    case noAccount
    case restricted
    case couldNotDetermine
    case failedToCheckAccountStatus(Error)
    case failedToFetchAccountId(Error?)
}
