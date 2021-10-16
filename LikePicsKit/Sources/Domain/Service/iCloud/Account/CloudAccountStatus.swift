//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public enum CloudAccountStatus {
    case available(identifier: String)
    case noAccount
    case couldNotDetermine
    case restricted
}
