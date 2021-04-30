//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipCollection {
    enum Source: Equatable {
        case all
        case album(Album.Identity)
        case tag(Tag)
        case uncategorized
        case search(ClipSearchQuery)

        var isAlbum: Bool {
            switch self {
            case .album:
                return true

            default:
                return false
            }
        }
    }
}
