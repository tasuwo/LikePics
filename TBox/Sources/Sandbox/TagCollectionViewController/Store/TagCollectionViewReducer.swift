//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

typealias TagCollectionViewDependency = HasClipCommandService & HasRouter & HasPasteboard

enum TagCollectionViewReducer: Reducer {
    typealias Dependency = TagCollectionViewDependency
    typealias State = TagCollectionViewState
    typealias Action = TagCollectionViewAction

    typealias Layout = TagCollectionViewLayout

    // MARK: - Methods

    static func execute(action: Action, state: State, dependency: Dependency) -> State {
        switch action {
        case let .tagsUpdated(tags):
            var nextState = performFilter(by: tags, previousState: state)
            if nextState.shouldClearQuery {
                nextState = nextState.updating(searchQuery: "")
            }
            nextState = nextState.updating(isCollectionViewDisplaying: !tags.isEmpty,
                                           isEmptyMessageViewDisplaying: tags.isEmpty,
                                           isSearchBarEnabled: !tags.isEmpty)
            return nextState

        case let .searchQueryChanged(query):
            var nextState = performFilter(bySearchQuery: query, previousState: state)
            if nextState.shouldClearQuery {
                nextState = nextState.updating(searchQuery: "")
            }
            return nextState

        case let .settingUpdated(isHiddenItemEnabled: isHiddenItemEnabled):
            return performFilter(byHiddenItemAvailability: isHiddenItemEnabled, previousState: state)

        case let .select(tag):
            dependency.router.showClipCollectionView(for: tag)
            return state

        case let .delete(tagIds):
            switch dependency.commandService.deleteTags(having: tagIds) {
            case .success:
                return state

            case .failure:
                return state.updating(alert: .error(L10n.errorTagDelete))
            }

        case let .hide(tagId):
            switch dependency.commandService.updateTag(having: tagId, byHiding: true) {
            case .success:
                return state

            case .failure:
                return state.updating(alert: .error(L10n.errorTagDefault))
            }

        case let .reveal(tagId):
            switch dependency.commandService.updateTag(having: tagId, byHiding: false) {
            case .success:
                return state

            case .failure:
                return state.updating(alert: .error(L10n.errorTagDefault))
            }

        case let .update(tagId, name: name):
            switch dependency.commandService.updateTag(having: tagId, nameTo: name) {
            case .success:
                return state

            case .failure(.duplicated):
                return state.updating(alert: .error(L10n.errorTagRenameDuplicated))

            case .failure:
                return state.updating(alert: .error(L10n.errorTagDefault))
            }

        case .emptyMessageViewActionButtonTapped, .tagAdditionButtonTapped:
            return state.updating(alert: .addition)

        case .uncategorizedTagButtonTapped:
            dependency.router.showUncategorizedClipCollectionView()
            return state

        case let .alertSaveButtonTapped(text: text):
            switch state.alert {
            case .addition:
                switch dependency.commandService.create(tagWithName: text) {
                case .success:
                    return state.updating(alert: nil)

                case .failure(.duplicated):
                    return state.updating(alert: .error(L10n.errorTagRenameDuplicated))

                case .failure:
                    return state.updating(alert: .error(L10n.errorTagDefault))
                }

            case let .edit(tagId: tagId, name: _):
                switch dependency.commandService.updateTag(having: tagId, nameTo: text) {
                case .success:
                    return state.updating(alert: nil)

                case .failure(.duplicated):
                    return state.updating(alert: .error(L10n.errorTagRenameDuplicated))

                case .failure:
                    return state.updating(alert: .error(L10n.errorTagDefault))
                }

            default:
                return state.updating(alert: nil)
            }

        case .alertDismissed:
            return state.updating(alert: nil)
        }
    }
}

// MARK: Filter

extension TagCollectionViewReducer {
    private static func performFilter(by tags: [Tag], previousState: State) -> State {
        return performFilter(tags: tags,
                             searchQuery: previousState.searchQuery,
                             isHiddenItemEnabled: previousState.isHiddenItemEnabled,
                             previousState: previousState)
    }

    private static func performFilter(bySearchQuery searchQuery: String, previousState: State) -> State {
        return performFilter(tags: previousState._tags,
                             searchQuery: searchQuery,
                             isHiddenItemEnabled: previousState.isHiddenItemEnabled,
                             previousState: previousState)
    }

    private static func performFilter(byHiddenItemAvailability isHiddenItemEnabled: Bool, previousState: State) -> State {
        return performFilter(tags: previousState._tags,
                             searchQuery: previousState.searchQuery,
                             isHiddenItemEnabled: isHiddenItemEnabled,
                             previousState: previousState)
    }

    private static func performFilter(tags: [Tag],
                                      searchQuery: String,
                                      isHiddenItemEnabled: Bool,
                                      previousState: State) -> State
    {
        var searchStorage = previousState._searchStorage

        let tags = tags
            .filter { isHiddenItemEnabled ? $0.isHidden == false : true }

        let filteredTags = searchStorage.perform(query: searchQuery, to: tags)
        let items: [Layout.Item] = (
            [searchQuery.isEmpty ? .uncategorized : nil]
                + filteredTags.map { .tag(Layout.Item.ListingTag(tag: $0, displayCount: !isHiddenItemEnabled)) }
        ).compactMap { $0 }

        return previousState.updating(items: items,
                                      searchQuery: searchQuery,
                                      isHiddenItemEnabled: isHiddenItemEnabled,
                                      _tags: tags,
                                      _searchStorage: searchStorage)
    }
}

private extension TagCollectionViewState {
    var shouldClearQuery: Bool { _tags.isEmpty && !searchQuery.isEmpty }
}
