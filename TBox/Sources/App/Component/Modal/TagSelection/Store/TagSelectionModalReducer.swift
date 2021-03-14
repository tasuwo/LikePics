//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias TagSelectionModalDependency = HasUserSettingStorage
    & HasClipCommandService
    & HasClipQueryService
    & HasTagSelectionModalSubscription

enum TagSelectionModalReducer: Reducer {
    typealias Dependency = TagSelectionModalDependency
    typealias State = TagSelectionModalState
    typealias Action = TagSelectionModalAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return (state, prepareQueryEffects(dependency))

        case .viewDidDisappear:
            dependency.tagSelectionCompleted(Set(state.tags.selectedValues))
            return (nextState, .none)

        // MARK: State Observation

        case let .tagsUpdated(tags):
            nextState = performFilter(tags: tags, previousState: state)
            return (nextState, .none)

        case let .searchQueryChanged(query):
            nextState = performFilter(searchQuery: query, previousState: state)
            return (nextState, .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            nextState = performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state)
            return (nextState, .none)

        // MARK: Selection

        case let .selected(tagId):
            let newTags = state.tags.updated(_selectedIds: state.tags._selectedIds.union(Set([tagId])))
            nextState.tags = newTags
            return (nextState, .none)

        case let .deselected(tagId):
            let newTags = state.tags.updated(_selectedIds: state.tags._selectedIds.subtracting(Set([tagId])))
            nextState.tags = newTags
            return (nextState, .none)

        // MARK: Button Action

        case .emptyMessageViewActionButtonTapped, .addButtonTapped:
            nextState.alert = .addition
            return (nextState, .none)

        case .saveButtonTapped:
            nextState.isDismissed = true
            return (nextState, .none)

        // MARK: Alert Completion

        case let .alertSaveButtonTapped(text: name):
            switch dependency.clipCommandService.create(tagWithName: name) {
            case let .success(tagId):
                let newTags = state.tags.updated(_selectedIds: state.tags._selectedIds.union(Set([tagId])))
                nextState.tags = newTags
                nextState.alert = nil

            case .failure(.duplicated):
                nextState.alert = .error(L10n.errorTagRenameDuplicated)

            case .failure:
                nextState.alert = .error(L10n.errorTagDefault)
            }
            return (nextState, .none)

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)
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
                      isSomeItemsHidden: previousState._isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(searchQuery: String,
                                      previousState: State) -> State
    {
        performFilter(tags: previousState.tags.orderedValues,
                      searchQuery: searchQuery,
                      isSomeItemsHidden: previousState._isSomeItemsHidden,
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
        var nextState = previousState
        var searchStorage = previousState._searchStorage

        let filteringTags = tags.filter { isSomeItemsHidden ? $0.isHidden == false : true }
        let filteredTagIds = searchStorage.perform(query: searchQuery, to: filteringTags).map { $0.id }

        let newTags = previousState.tags
            .updated(_values: tags.indexed())
            .updated(_displayableIds: Set(filteredTagIds))
        nextState.tags = newTags

        nextState.searchQuery = searchQuery
        nextState._isSomeItemsHidden = isSomeItemsHidden
        nextState.isCollectionViewDisplaying = !filteringTags.isEmpty
        nextState.isEmptyMessageViewDisplaying = filteringTags.isEmpty
        nextState._searchStorage = searchStorage

        if filteringTags.isEmpty, !searchQuery.isEmpty {
            nextState.searchQuery = ""
        }

        return nextState
    }
}
