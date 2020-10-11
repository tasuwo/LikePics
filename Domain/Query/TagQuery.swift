//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol TagQuery {
    var tag: CurrentValueSubject<Tag, Error> { get }
}
