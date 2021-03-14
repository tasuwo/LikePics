//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipCollection {
    enum Source: Equatable {
        enum SearchQuery: Equatable {
            case keywords([String])
            case tag(Tag?)
        }

        case all
        case album(Album.Identity)
        case search(SearchQuery)

        var isAlbum: Bool {
            switch self {
            case .album:
                return true

            default:
                return false
            }
        }

        var searchQuery: SearchQuery? {
            switch self {
            case let .search(query):
                return query

            default:
                return nil
            }
        }
    }
}
