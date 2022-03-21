//
//  Copyright ©︎ 2022 Tasuku Tozawa. All rights reserved.
//

import Domain

/// @mockable
public protocol HasCloudStackLoader {
    var cloudStackLoader: CloudStackLoadable { get }
}
