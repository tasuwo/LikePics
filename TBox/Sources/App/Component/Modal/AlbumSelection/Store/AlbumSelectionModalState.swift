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
    var searchStorage: SearchableStorage<Album>
    var albums: Collection<Album>
    var selectedAlbumId: Album.Identity?

    var isCollectionViewHidden: Bool
    var isEmptyMessageViewHidden: Bool
    var isSearchBarEnabled: Bool
    var isSomeItemsHidden: Bool

    var alert: Alert?

    var isDismissed: Bool
}

extension AlbumSelectionModalState {
    init(isSomeItemsHidden: Bool) {
        searchQuery = ""
        searchStorage = .init()
        albums = .init()
        selectedAlbumId = nil

        isCollectionViewHidden = true
        isEmptyMessageViewHidden = true
        isSearchBarEnabled = false
        self.isSomeItemsHidden = isSomeItemsHidden

        alert = nil

        isDismissed = false
    }
}

extension AlbumSelectionModalState {
    var emptyMessageViewAlpha: CGFloat {
        isEmptyMessageViewHidden ? 0 : 1
    }
}
