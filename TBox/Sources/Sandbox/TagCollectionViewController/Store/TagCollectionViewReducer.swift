//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias TagCollectionViewDependency = HasClipCommandService
    & HasRouter
    & HasPasteboard
    & HasClipQueryService
    & HasUserSettingStorage

enum TagCollectionViewReducer: Reducer {
    typealias Dependency = TagCollectionViewDependency
    typealias State = TagCollectionViewState
    typealias Action = TagCollectionViewAction

    typealias Layout = TagCollectionViewLayout

    // MARK: - Methods

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        switch action {
        case .viewDidLoad:
            return (state, prepareQueryEffects(dependency))

        case let .tagsUpdated(tags):
            var nextState = performFilter(by: tags, previousState: state)
            if nextState.shouldClearQuery {
                nextState = nextState.updating(searchQuery: "")
            }
            nextState = nextState.updating(isCollectionViewDisplaying: !tags.isEmpty,
                                           isEmptyMessageViewDisplaying: tags.isEmpty,
                                           isSearchBarEnabled: !tags.isEmpty)
            return (nextState, .none)

        case let .searchQueryChanged(query):
            var nextState = performFilter(bySearchQuery: query, previousState: state)
            if nextState.shouldClearQuery {
                nextState = nextState.updating(searchQuery: "")
            }
            return (nextState, .none)

        case let .settingUpdated(isHiddenItemEnabled: isHiddenItemEnabled):
            return (performFilter(byHiddenItemAvailability: isHiddenItemEnabled, previousState: state), .none)

        case let .select(tag):
            dependency.router.showClipCollectionView(for: tag)
            return (state, .none)

        case let .delete(tagIds):
            switch dependency.clipCommandService.deleteTags(having: tagIds) {
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.errorTagDelete)), .none)
            }

        case let .hide(tagId):
            switch dependency.clipCommandService.updateTag(having: tagId, byHiding: true) {
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.errorTagDefault)), .none)
            }

        case let .reveal(tagId):
            switch dependency.clipCommandService.updateTag(having: tagId, byHiding: false) {
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.errorTagDefault)), .none)
            }

        case let .update(tagId, name: name):
            switch dependency.clipCommandService.updateTag(having: tagId, nameTo: name) {
            case .success:
                return (state, .none)

            case .failure(.duplicated):
                return (state.updating(alert: .error(L10n.errorTagRenameDuplicated)), .none)

            case .failure:
                return (state.updating(alert: .error(L10n.errorTagDefault)), .none)
            }

        case .emptyMessageViewActionButtonTapped, .tagAdditionButtonTapped:
            return (state.updating(alert: .addition), .none)

        case .uncategorizedTagButtonTapped:
            dependency.router.showUncategorizedClipCollectionView()
            return (state, .none)

        case let .alertSaveButtonTapped(text: text):
            switch state.alert {
            case .addition:
                switch dependency.clipCommandService.create(tagWithName: text) {
                case .success:
                    return (state.updating(alert: nil), .none)

                case .failure(.duplicated):
                    return (state.updating(alert: .error(L10n.errorTagRenameDuplicated)), .none)

                case .failure:
                    return (state.updating(alert: .error(L10n.errorTagDefault)), .none)
                }

            case let .edit(tagId: tagId, name: _):
                switch dependency.clipCommandService.updateTag(having: tagId, nameTo: text) {
                case .success:
                    return (state.updating(alert: nil), .none)

                case .failure(.duplicated):
                    return (state.updating(alert: .error(L10n.errorTagRenameDuplicated)), .none)

                case .failure:
                    return (state.updating(alert: .error(L10n.errorTagDefault)), .none)
                }

            default:
                return (state.updating(alert: nil), .none)
            }

        case .alertDismissed:
            return (state.updating(alert: nil), .none)
        }
    }
}

extension TagCollectionViewReducer {
    private static func prepareQueryEffects(_ dependency: Dependency) -> [Effect<Action>] {
        let query: TagListQuery
        switch dependency.clipQueryService.queryAllTags() {
        case let .success(result):
            query = result

        case let .failure(error):
            fatalError("Failed to load tags: \(error.localizedDescription)")
        }

        let tagsStream = query.tags
            .catch { _ in Just([]) }
            .map { Action.tagsUpdated($0) as Action? }
        let tagsEffect = Effect(tagsStream, underlying: query)

        let settingsStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.settingUpdated(isHiddenItemEnabled: !$0) as Action? }
        let settingsEffect = Effect(settingsStream)

        return [tagsEffect, settingsEffect]
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
