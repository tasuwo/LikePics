//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import Domain
import Foundation

public struct AlbumMultiSelectionModalState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case addition
    }

    let id: UUID

    var searchQuery: String
    var searchStorage: SearchableStorage<ListingAlbumTitle>
    var albums: EntityCollectionSnapshot<ListingAlbumTitle>

    var isCollectionViewHidden: Bool
    var isEmptyMessageViewHidden: Bool
    var isSearchBarEnabled: Bool
    var isSomeItemsHidden: Bool

    var alert: Alert?

    var isDismissed: Bool
}

public extension AlbumMultiSelectionModalState {
    init(id: UUID, selections: Set<Album.Identity>, isSomeItemsHidden: Bool) {
        self.id = id

        searchQuery = ""
        searchStorage = .init()
        albums = .init(selectedIds: selections)

        isCollectionViewHidden = true
        isEmptyMessageViewHidden = true
        isSearchBarEnabled = false
        self.isSomeItemsHidden = isSomeItemsHidden

        alert = nil

        isDismissed = false
    }
}

extension AlbumMultiSelectionModalState {
    var filteredOrderedAlbums: Set<Ordered<ListingAlbumTitle>> {
        let albums = albums
            .filteredOrderedEntities()
        return Set(albums)
    }

    var orderedFilteredAlbums: [ListingAlbumTitle] {
        albums
            .orderedFilteredEntities()
    }

    var emptyMessageViewAlpha: CGFloat {
        isEmptyMessageViewHidden ? 0 : 1
    }
}
