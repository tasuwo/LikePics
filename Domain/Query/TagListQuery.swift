//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol TagListQuery {
    var tags: CurrentValueSubject<[Tag], Error> { get }
}
