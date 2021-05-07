//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import CoreGraphics
import Domain

struct AlbumSelectionModalState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case addition
    }

    var searchQuery: String
    var albums: Collection<Album>
    var selectedAlbumId: Album.Identity?

    var isCollectionViewHidden: Bool
    var isEmptyMessageViewHidden: Bool
    var isSearchBarEnabled: Bool

    var alert: Alert?

    var isDismissed: Bool

    var _isSomeItemsHidden: Bool
    var _searchStorage: SearchableStorage<Album>
}

extension AlbumSelectionModalState {
    var emptyMessageViewAlpha: CGFloat {
        isEmptyMessageViewHidden ? 0 : 1
    }
}
