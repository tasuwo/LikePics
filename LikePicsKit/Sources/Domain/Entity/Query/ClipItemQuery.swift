//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol ClipItemQuery {
    var clipItem: CurrentValueSubject<ClipItem, Error> { get }
}
