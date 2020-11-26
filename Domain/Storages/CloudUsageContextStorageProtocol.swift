//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol CloudUsageContextStorageProtocol {
    var lastLoggedInCloudAccountId: String? { get }
    func set(lastLoggedInCloudAccountId: String?)
}
