//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public protocol CloudAccountServiceProtocol {
    static func resolve(_ completion: @escaping (Result<CloudAccountStatus, Error>) -> Void)
}
