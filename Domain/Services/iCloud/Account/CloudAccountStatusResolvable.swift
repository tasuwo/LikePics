//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol CloudAccountStatusResolvable {
    static func resolve(_ completion: @escaping (Result<CloudAccountIdentifier, CloudAccountStatusError>) -> Void)
}
