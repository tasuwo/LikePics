//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Combine

public protocol AlbumQuery {
    var album: CurrentValueSubject<Album, Error> { get }
}
