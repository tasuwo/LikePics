//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

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
    var albums: Collection<Album>

    var isEditing: Bool
    var isEmptyMessageViewDisplaying: Bool
    var isCollectionViewDisplaying: Bool
    var isSearchBarEnabled: Bool
    var isAddButtonEnabled: Bool
    var isDragInteractionEnabled: Bool

    var alert: Alert?

    var _isSomeItemsHidden: Bool
    var _searchStorage: SearchableStorage<Album>
}

extension AlbumListViewState {
    var isEditButtonEnabled: Bool { !albums.displayableValues.isEmpty }
    var displayableAlbums: [Album] {
        albums
            .displayableValues
            .map { _isSomeItemsHidden ? $0.removingHiddenClips() : $0 }
    }

    var emptyMessageViewAlpha: CGFloat {
        isEmptyMessageViewDisplaying ? 1 : 0
    }

    var collectionViewAlpha: CGFloat {
        isCollectionViewDisplaying ? 1 : 0
    }
}
