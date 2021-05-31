//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol ListingClipListQuery {
    var clips: CurrentValueSubject<[ListingClip], Error> { get }
}
