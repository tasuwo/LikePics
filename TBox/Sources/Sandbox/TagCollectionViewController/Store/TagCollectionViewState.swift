//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import Domain

struct TagCollectionViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case edit(tagId: Tag.Identity, name: String)
        case addition
    }

    let items: [TagCollectionViewLayout.Item]
    let searchQuery: String
    let isHiddenItemEnabled: Bool

    let isCollectionViewDisplaying: Bool
    let isEmptyMessageViewDisplaying: Bool
    let isSearchBarEnabled: Bool

    let alert: Alert?

    let _tags: [Tag]
    let _searchStorage: SearchableStorage<Tag>

    // MARK: - Methods

    func updating(searchQuery: String) -> Self {
        return .init(items: items,
                     searchQuery: searchQuery,
                     isHiddenItemEnabled: isHiddenItemEnabled,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _tags: _tags,
                     _searchStorage: _searchStorage)
    }

    func updating(alert: Alert?) -> Self {
        return .init(items: items,
                     searchQuery: searchQuery,
                     isHiddenItemEnabled: isHiddenItemEnabled,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _tags: _tags,
                     _searchStorage: _searchStorage)
    }

    func updating(isCollectionViewDisplaying: Bool,
                  isEmptyMessageViewDisplaying: Bool,
                  isSearchBarEnabled: Bool) -> Self
    {
        return .init(items: items,
                     searchQuery: searchQuery,
                     isHiddenItemEnabled: isHiddenItemEnabled,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _tags: _tags,
                     _searchStorage: _searchStorage)
    }

    func updating(items: [TagCollectionViewLayout.Item],
                  searchQuery: String,
                  isHiddenItemEnabled: Bool,
                  _tags: [Tag],
                  _searchStorage: SearchableStorage<Tag>) -> Self
    {
        return .init(items: items,
                     searchQuery: searchQuery,
                     isHiddenItemEnabled: isHiddenItemEnabled,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _tags: _tags,
                     _searchStorage: _searchStorage)
    }
}
