//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

/// @mockable
public protocol ListingAlbumListQuery {
    var albums: CurrentValueSubject<[ListingAlbum], Error> { get }
}
