//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

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
    var filteredOrderedAlbums: Set<Ordered<Album>> {
        let albums = albums
            .filteredOrderedValues()
            .map { Ordered(index: $0.index, value: isSomeItemsHidden ? $0.value.removingHiddenClips() : $0.value) }
        return Set(albums)
    }

    var orderedFilteredAlbums: [Album] {
        albums
            .orderedFilteredValues()
            .map { isSomeItemsHidden ? $0.removingHiddenClips() : $0 }
    }

    var emptyMessageViewAlpha: CGFloat {
        isEmptyMessageViewHidden ? 0 : 1
    }
}
