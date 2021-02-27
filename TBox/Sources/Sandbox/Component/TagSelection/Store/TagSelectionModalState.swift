//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import Domain

struct TagSelectionModalState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case addition
    }

    let isDismissed: Bool

    let tags: Collection<Tag>

    let searchQuery: String
    let isSomeItemsHidden: Bool

    let isCollectionViewDisplaying: Bool
    let isEmptyMessageViewDisplaying: Bool
    let isSearchBarEnabled: Bool

    let alert: Alert?

    let _searchStorage: SearchableStorage<Tag>
}

extension TagSelectionModalState {
    func updating(isDismissed: Bool) -> Self {
        return .init(isDismissed: isDismissed,
                     tags: tags,
                     searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }

    func updated(tags: Collection<Tag>) -> Self {
        return .init(isDismissed: isDismissed,
                     tags: tags,
                     searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }

    func updating(alert: Alert?) -> Self {
        return .init(isDismissed: isDismissed,
                     tags: tags,
                     searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }

    func updating(searchQuery: String) -> Self {
        return .init(isDismissed: isDismissed,
                     tags: tags,
                     searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }

    func updating(isSomeItemsHidden: Bool) -> Self {
        return .init(isDismissed: isDismissed,
                     tags: tags,
                     searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }

    func updating(isCollectionViewDisplaying: Bool,
                  isEmptyMessageViewDisplaying: Bool) -> Self
    {
        return .init(isDismissed: isDismissed,
                     tags: tags,
                     searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }

    func updating(_searchStorage: SearchableStorage<Tag>) -> Self {
        return .init(isDismissed: isDismissed,
                     tags: tags,
                     searchQuery: searchQuery,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _searchStorage: _searchStorage)
    }
}
