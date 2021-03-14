//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import Domain

struct AlbumSelectionModalState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case addition
    }

    var searchQuery: String
    var albums: Collection<Album>
    var selectedAlbumId: Album.Identity?

    var isCollectionViewDisplaying: Bool
    var isEmptyMessageViewDisplaying: Bool
    var isSearchBarEnabled: Bool

    var alert: Alert?

    var isDismissed: Bool

    var _isSomeItemsHidden: Bool
    var _searchStorage: SearchableStorage<Album>
}
