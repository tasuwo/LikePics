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
    let initialSelections: Set<Album.Identity>

    var searchQuery: String
    var searchStorage: SearchableStorage<ListingAlbumTitle>
    var albums: EntityCollectionSnapshot<ListingAlbumTitle>

    var isCollectionViewHidden: Bool
    var isEmptyMessageViewHidden: Bool
    var isSearchBarEnabled: Bool
    var isSomeItemsHidden: Bool

    var quickAddButtonTitle: String?
    var isQuickAddButtonHidden: Bool

    var alert: Alert?

    var isDismissed: Bool
}

extension AlbumMultiSelectionModalState {
    public init(id: UUID, selections: Set<Album.Identity>, isSomeItemsHidden: Bool) {
        self.id = id
        initialSelections = selections

        searchQuery = ""
        searchStorage = .init()
        albums = .init()

        isCollectionViewHidden = true
        isEmptyMessageViewHidden = true
        isSearchBarEnabled = false
        isQuickAddButtonHidden = true
        self.isSomeItemsHidden = isSomeItemsHidden

        alert = nil

        isDismissed = false
    }
}

extension AlbumMultiSelectionModalState {
    var filteredOrderedAlbums: Set<Ordered<ListingAlbumTitle>> {
        let albums =
            albums
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
