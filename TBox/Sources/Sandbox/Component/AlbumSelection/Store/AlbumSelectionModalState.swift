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

    let searchQuery: String
    let isSomeItemsHidden: Bool

    let isCollectionViewDisplaying: Bool
    let isEmptyMessageViewDisplaying: Bool
    let isSearchBarEnabled: Bool

    let alert: Alert?

    let _albums: [Album.Identity: Ordered<Album>]
    let _filteredAlbumIds: Set<Album.Identity>
    let _searchStorage: SearchableStorage<Album>
}

extension AlbumSelectionModalState {
    var albums: [Album] {
        _filteredAlbumIds
            .compactMap { id in _albums[id] }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }

    var _orderedAlbums: [Album] {
        _albums
            .map { $0.value }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }
}

extension AlbumSelectionModalState {
    func updating(isSomeItemsHidden: Bool) -> Self {
        return .init(searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _albums: _albums,
                     _filteredAlbumIds: _filteredAlbumIds,
                     _searchStorage: _searchStorage)
    }

    func updating(isCollectionViewDisplaying: Bool) -> Self {
        return .init(searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _albums: _albums,
                     _filteredAlbumIds: _filteredAlbumIds,
                     _searchStorage: _searchStorage)
    }

    func updating(isEmptyMessageViewDisplaying: Bool) -> Self {
        return .init(searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _albums: _albums,
                     _filteredAlbumIds: _filteredAlbumIds,
                     _searchStorage: _searchStorage)
    }

    func updating(_albums: [Album.Identity: Ordered<Album>]) -> Self {
        return .init(searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _albums: _albums,
                     _filteredAlbumIds: _filteredAlbumIds,
                     _searchStorage: _searchStorage)
    }

    func updating(_filteredAlbumIds: Set<Album.Identity>) -> Self {
        return .init(searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _albums: _albums,
                     _filteredAlbumIds: _filteredAlbumIds,
                     _searchStorage: _searchStorage)
    }

    func updating(_searchStorage: SearchableStorage<Album>) -> Self {
        return .init(searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _albums: _albums,
                     _filteredAlbumIds: _filteredAlbumIds,
                     _searchStorage: _searchStorage)
    }

    func updating(searchQuery: String) -> Self {
        return .init(searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _albums: _albums,
                     _filteredAlbumIds: _filteredAlbumIds,
                     _searchStorage: _searchStorage)
    }

    func updating(alert: Alert?) -> Self {
        return .init(searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _albums: _albums,
                     _filteredAlbumIds: _filteredAlbumIds,
                     _searchStorage: _searchStorage)
    }
}
