//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain

typealias TagSelectionModalDependency = HasUserSettingStorage
    & HasClipCommandService
    & HasClipQueryService
    & HasModalNotificationCenter

struct TagSelectionModalReducer: Reducer {
    typealias Dependency = TagSelectionModalDependency
    typealias State = TagSelectionModalState
    typealias Action = TagSelectionModalAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return Self.prepareQueryEffects(state, dependency)

        // MARK: State Observation

        case let .tagsUpdated(tags):
            nextState = Self.performFilter(tags: tags, previousState: state)
            return (nextState, .none)

        case let .searchQueryChanged(query):
            nextState = Self.performFilter(searchQuery: query, previousState: state)
            return (nextState, .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            nextState = Self.performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state)
            return (nextState, .none)

        // MARK: Selection

        case let .selected(tagId):
            let newTags = state.tags.updated(selectedIds: state.tags._selectedIds.union(Set([tagId])))
            nextState.tags = newTags
            return (nextState, .none)

        case let .deselected(tagId):
            let newTags = state.tags.updated(selectedIds: state.tags._selectedIds.subtracting(Set([tagId])))
            nextState.tags = newTags
            return (nextState, .none)

        // MARK: Button Action

        case .emptyMessageViewActionButtonTapped, .addButtonTapped:
            nextState.alert = .addition
            return (nextState, .none)

        case .saveButtonTapped:
            var userInfo: [ModalNotification.UserInfoKey: Any] = [:]
            userInfo[.selectedTags] = Set(state.tags.orderedSelectedEntities())
            dependency.modalNotificationCenter.post(id: state.id, name: .tagSelectionModalDidSelect, userInfo: userInfo)
            nextState.isDismissed = true
            return (nextState, .none)

        // MARK: Alert Completion

        case let .alertSaveButtonTapped(text: name):
            switch dependency.clipCommandService.create(tagWithName: name) {
            case let .success(tagId):
                let newTags = state.tags.updated(selectedIds: state.tags._selectedIds.union(Set([tagId])))
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

        // MARK: Transition

        case .didDismissedManually:
            dependency.modalNotificationCenter.post(id: state.id, name: .tagSelectionModalDidDismiss, userInfo: nil)
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension TagSelectionModalReducer {
    static func prepareQueryEffects(_ state: State, _ dependency: Dependency) -> (State, [Effect<Action>]) {
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

        let nextState = performFilter(tags: query.tags.value,
                                      searchQuery: state.searchQuery,
                                      isSomeItemsHidden: !dependency.userSettingStorage.readShowHiddenItems(),
                                      previousState: state)

        return (nextState, [tagsEffect, settingsEffect])
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
        performFilter(tags: previousState.tags.orderedEntities(),
                      searchQuery: searchQuery,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        performFilter(tags: previousState.tags.orderedEntities(),
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
        var searchStorage = previousState.searchStorage

        let filteringTags = tags.filter { isSomeItemsHidden ? $0.isHidden == false : true }
        let filteredTagIds = searchStorage.perform(query: searchQuery, to: filteringTags).map { $0.id }

        let newTags = previousState.tags
            .updated(entities: tags)
            .updated(filteredIds: Set(filteredTagIds))
        nextState.tags = newTags

        nextState.searchQuery = searchQuery
        nextState.isSomeItemsHidden = isSomeItemsHidden
        nextState.isCollectionViewHidden = filteringTags.isEmpty
        nextState.isEmptyMessageViewHidden = !filteringTags.isEmpty
        nextState.searchStorage = searchStorage

        if filteringTags.isEmpty, !searchQuery.isEmpty {
            nextState.searchQuery = ""
        }

        return nextState
    }
}

// MARK: - ModalNotification

extension ModalNotification.Name {
    static let tagSelectionModalDidSelect = ModalNotification.Name("net.tasuwo.TBox.TagSelectionModalReducer.tagSelectionModalDidSelect")
    static let tagSelectionModalDidDismiss = ModalNotification.Name("net.tasuwo.TBox.TagSelectionModalReducer.tagSelectionModalDidDismiss")
}

extension ModalNotification.UserInfoKey {
    static let selectedTags = ModalNotification.UserInfoKey("net.tasuwo.TBox.TagSelectionModalReducer.selectedTags")
}
