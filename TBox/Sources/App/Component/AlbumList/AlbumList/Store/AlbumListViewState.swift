//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import Domain

struct AlbumListViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case addition
        case renaming(albumId: Album.Identity, title: String)
        case deletion(albumId: Album.Identity, title: String)
    }

    var searchQuery: String
    var searchStorage: SearchableStorage<Album>
    var albums: Collection<Album>

    var isEditing: Bool
    var isEmptyMessageViewDisplaying: Bool
    var isCollectionViewDisplaying: Bool
    var isSearchBarEnabled: Bool
    var isAddButtonEnabled: Bool
    var isDragInteractionEnabled: Bool
    var isSomeItemsHidden: Bool

    var alert: Alert?
}

extension AlbumListViewState {
    init(isSomeItemsHidden: Bool) {
        searchQuery = ""
        searchStorage = .init()
        albums = .init()

        isEditing = false
        isEmptyMessageViewDisplaying = false
        isCollectionViewDisplaying = false
        isSearchBarEnabled = false
        isAddButtonEnabled = true
        isDragInteractionEnabled = false

        alert = nil
        self.isSomeItemsHidden = isSomeItemsHidden
    }
}

extension AlbumListViewState {
    var isEditButtonEnabled: Bool {
        !albums.filteredValues().isEmpty
    }

    var displayableAlbums: [Album] {
        albums
            .orderedFilteredValues()
            .map { isSomeItemsHidden ? $0.removingHiddenClips() : $0 }
    }

    var emptyMessageViewAlpha: CGFloat {
        isEmptyMessageViewDisplaying ? 1 : 0
    }

    var collectionViewAlpha: CGFloat {
        isCollectionViewDisplaying ? 1 : 0
    }
}
