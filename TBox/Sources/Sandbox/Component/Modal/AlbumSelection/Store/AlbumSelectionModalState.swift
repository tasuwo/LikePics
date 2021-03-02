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
    let albums: Collection<Album>
    let isSomeItemsHidden: Bool

    let isCollectionViewDisplaying: Bool
    let isEmptyMessageViewDisplaying: Bool
    let isSearchBarEnabled: Bool

    let alert: Alert?

    let _searchStorage: SearchableStorage<Album>
}

extension AlbumSelectionModalState {
    func updating(isSomeItemsHidden: Bool) -> Self {
        return .init(searchQuery: searchQuery,
                     albums: albums,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }

    func updating(isCollectionViewDisplaying: Bool) -> Self {
        return .init(searchQuery: searchQuery,
                     albums: albums,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }

    func updating(isEmptyMessageViewDisplaying: Bool) -> Self {
        return .init(searchQuery: searchQuery,
                     albums: albums,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }

    func updating(albums: Collection<Album>) -> Self {
        return .init(searchQuery: searchQuery,
                     albums: albums,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }

    func updating(_searchStorage: SearchableStorage<Album>) -> Self {
        return .init(searchQuery: searchQuery,
                     albums: albums,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }

    func updating(searchQuery: String) -> Self {
        return .init(searchQuery: searchQuery,
                     albums: albums,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }

    func updating(alert: Alert?) -> Self {
        return .init(searchQuery: searchQuery,
                     albums: albums,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }
}
