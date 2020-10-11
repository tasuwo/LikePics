//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol ClipListQuery {
    var clips: CurrentValueSubject<[Clip], Error> { get }
}
