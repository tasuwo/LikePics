//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol CloudAccountServiceProtocol {
    var accountStatus: AnyPublisher<CloudAccountStatus?, Error> { get }
    func currentAccountStatus(_ completion: @escaping (Result<CloudAccountStatus, Error>) -> Void)
}
