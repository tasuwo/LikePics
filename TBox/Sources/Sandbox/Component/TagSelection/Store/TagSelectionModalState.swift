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

    struct OrderedTag: Equatable {
        let index: Int
        let value: Tag
    }

    var tags: [Tag] {
        _filteredTagIds
            .compactMap { id in _tags[id] }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }

    var selectedTags: [Tag] {
        selections
            .compactMap { id in _tags[id] }
            .sorted(by: { $0.index < $1.index })
            .compactMap { $0.value }
    }

    var displayableSelections: Set<Tag.Identity> {
        selections.filter { _filteredTagIds.contains($0) }
    }

    let searchQuery: String
    let initialSelections: Set<Tag.Identity>
    let selections: Set<Tag.Identity>
    let isSomeItemsHidden: Bool

    let isCollectionViewDisplaying: Bool
    let isEmptyMessageViewDisplaying: Bool
    let isSearchBarEnabled: Bool

    let alert: Alert?

    var _orderedTags: [Tag] {
        _tags
            .map { $0.value }
            .sorted(by: { $0.index < $1.index })
            .map { $0.value }
    }

    let _tags: [Tag.Identity: OrderedTag]
    let _filteredTagIds: Set<Tag.Identity>
    let _searchStorage: SearchableStorage<Tag>
}

extension TagSelectionModalState {
    func newSelectedTags(from previous: Self) -> Set<Tag> {
        let additions = displayableSelections.subtracting(previous.displayableSelections)
        return Set(additions.compactMap { _tags[$0]?.value })
    }

    func newDeselectedTags(from previous: Self) -> Set<Tag> {
        let deletions = previous.displayableSelections.subtracting(displayableSelections)
        return Set(deletions.compactMap { _tags[$0]?.value })
    }
}

extension TagSelectionModalState {
    func updating(alert: Alert?) -> Self {
        return .init(searchQuery: searchQuery,
                     initialSelections: initialSelections,
                     selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _tags: _tags,
                     _filteredTagIds: _filteredTagIds,
                     _searchStorage: _searchStorage)
    }

    func updating(selections: Set<Tag.Identity>) -> Self {
        return .init(searchQuery: searchQuery,
                     initialSelections: initialSelections,
                     selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _tags: _tags,
                     _filteredTagIds: _filteredTagIds,
                     _searchStorage: _searchStorage)
    }

    func updating(searchQuery: String) -> Self {
        return .init(searchQuery: searchQuery,
                     initialSelections: initialSelections,
                     selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _tags: _tags,
                     _filteredTagIds: _filteredTagIds,
                     _searchStorage: _searchStorage)
    }

    func updating(initialSelections: Set<Tag.Identity>) -> Self {
        return .init(searchQuery: searchQuery,
                     initialSelections: initialSelections,
                     selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _tags: _tags,
                     _filteredTagIds: _filteredTagIds,
                     _searchStorage: _searchStorage)
    }

    func updating(isSomeItemsHidden: Bool) -> Self {
        return .init(searchQuery: searchQuery,
                     initialSelections: initialSelections,
                     selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _tags: _tags,
                     _filteredTagIds: _filteredTagIds,
                     _searchStorage: _searchStorage)
    }

    func updating(isCollectionViewDisplaying: Bool,
                  isEmptyMessageViewDisplaying: Bool) -> Self
    {
        return .init(searchQuery: searchQuery,
                     initialSelections: initialSelections,
                     selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _tags: _tags,
                     _filteredTagIds: _filteredTagIds,
                     _searchStorage: _searchStorage)
    }

    func updating(_filteredTagIds: Set<Tag.Identity>,
                  _tags: [Tag.Identity: OrderedTag],
                  _searchStorage: SearchableStorage<Tag>) -> Self
    {
        return .init(searchQuery: searchQuery,
                     initialSelections: initialSelections,
                     selections: selections,
                     isSomeItemsHidden: isSomeItemsHidden,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isSearchBarEnabled: isSearchBarEnabled,
                     alert: alert,
                     _tags: _tags,
                     _filteredTagIds: _filteredTagIds,
                     _searchStorage: _searchStorage)
    }
}
