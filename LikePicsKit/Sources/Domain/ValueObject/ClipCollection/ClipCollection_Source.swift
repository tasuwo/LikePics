//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

public extension ClipCollection {
    enum Source: Equatable {
        case all
        case album(Album.Identity)
        case tag(Tag)
        case uncategorized
        case search(ClipSearchQuery)

        public var isAlbum: Bool {
            switch self {
            case .album:
                return true

            default:
                return false
            }
        }

        public var albumId: Album.Identity? {
            switch self {
            case let .album(albumId):
                return albumId

            default:
                return nil
            }
        }
    }
}
