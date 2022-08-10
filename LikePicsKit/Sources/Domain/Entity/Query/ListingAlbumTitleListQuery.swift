//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol ListingAlbumTitleListQuery {
    var albums: CurrentValueSubject<[ListingAlbumTitle], Error> { get }
}
