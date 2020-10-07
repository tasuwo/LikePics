//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol AlbumListQuery {
    var albums: CurrentValueSubject<[Album], Error> { get }
}
