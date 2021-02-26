//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias TagSelectionModalDependency = HasUserSettingStorage
    & HasClipCommandService
    & HasClipQueryService

enum TagSelectionModalReducer: Reducer {
    typealias Dependency = TagSelectionModalDependency
    typealias State = TagSelectionModalState
    typealias Action = TagSelectionModalAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return (state, prepareQueryEffects(dependency))

        // MARK: State Observation

        case let .tagsUpdated(tags):
            var nextState = performFilter(tags: tags, previousState: state)
            if nextState.shouldClearQuery {
                nextState = nextState.updating(searchQuery: "")
            }
            return (nextState, .none)

        case let .searchQueryChanged(query):
            var nextState = performFilter(searchQuery: query, previousState: state)
            if nextState.shouldClearQuery {
                nextState = nextState.updating(searchQuery: "")
            }
            return (nextState, .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state), .none)

        // MARK: Selection

        case let .selected(tagId):
            let newTags = state.tags.updated(_selectedIds: state.tags._selectedIds.union(Set([tagId])))
            let newState = state.updated(tags: newTags)
            return (newState, .none)

        case let .deselected(tagId):
            let newTags = state.tags.updated(_selectedIds: state.tags._selectedIds.subtracting(Set([tagId])))
            let newState = state.updated(tags: newTags)
            return (newState, .none)

        // MARK: Button Action

        case .emptyMessageViewActionButtonTapped, .addButtonTapped:
            return (state.updating(alert: .addition), .none)

        // MARK: Alert Completion

        case let .alertSaveButtonTapped(text: name):
            // TODO: 生成したタグを選択する
            switch dependency.clipCommandService.create(tagWithName: name) {
            case .success:
                return (state.updating(alert: nil), .none)

            case .failure(.duplicated):
                return (state.updating(alert: .error(L10n.errorTagRenameDuplicated)), .none)

            case .failure:
                return (state.updating(alert: .error(L10n.errorTagDefault)), .none)
            }

        case .alertDismissed:
            return (state.updating(alert: nil), .none)
        }
    }
}

// MARK: - Preparation

extension TagSelectionModalReducer {
    static func prepareQueryEffects(_ dependency: Dependency) -> [Effect<Action>] {
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
            .map { Action.settingUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingsEffect = Effect(settingsStream)

        return [tagsEffect, settingsEffect]
    }
}

// MARK: - Filter

extension TagSelectionModalReducer {
    private static func performFilter(tags: [Tag],
                                      previousState: State) -> State
    {
        performFilter(tags: tags,
                      searchQuery: previousState.searchQuery,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(searchQuery: String,
                                      previousState: State) -> State
    {
        performFilter(tags: previousState.tags.orderedValues,
                      searchQuery: searchQuery,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        performFilter(tags: previousState.tags.orderedValues,
                      searchQuery: previousState.searchQuery,
                      isSomeItemsHidden: isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(tags: [Tag],
                                      searchQuery: String,
                                      isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        var searchStorage = previousState._searchStorage

        let dict = tags.enumerated().reduce(into: [Tag.Identity: Ordered<Tag>]()) { dict, value in
            dict[value.element.id] = .init(index: value.offset, value: value.element)
        }

        let filteringTags = tags.filter { isSomeItemsHidden ? $0.isHidden == false : true }
        let filteredTagIds = searchStorage.perform(query: searchQuery, to: filteringTags).map { $0.id }

        let newTags = previousState.tags
            .updated(_values: dict)
            .updated(_displayableIds: Set(filteredTagIds))

        return previousState
            .updating(searchQuery: searchQuery)
            .updating(isSomeItemsHidden: isSomeItemsHidden)
            .updating(isCollectionViewDisplaying: !filteringTags.isEmpty,
                      isEmptyMessageViewDisplaying: filteringTags.isEmpty)
            .updating(_searchStorage: searchStorage)
            .updated(tags: newTags)
    }
}

private extension TagSelectionModalState {
    var shouldClearQuery: Bool { tags._values.isEmpty && !searchQuery.isEmpty }
}
