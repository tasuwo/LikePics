//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit

typealias ClipInformationDependency = HasClipQueryService
    & HasUserSettingStorage

struct ClipInformationReducer: Reducer {
    typealias Dependency = ClipInformationDependency
    typealias State = ClipInformationState
    typealias Action = ClipInformationAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return Self.prepareQueryEffects(for: state.clip.id, state: state, dependency: dependency)

        // MARK: State Observation

        case let .clipUpdated(clip):
            nextState.clip = clip.map(to: State.EditingClip.self)
            return (nextState, .none)

        case .clipDeleted:
            nextState.isDismissed = true
            return (nextState, .none)

        case let .itemsUpdated(items):
            let newItems = state.items
                .updated(entities: items.indexed())
                .updated(filteredIds: Set(items.map({ $0.identity })))
            nextState.items = newItems
            return (nextState, .none)

        case let .tagsUpdated(tags):
            return (Self.performFilter(tags: tags, previousState: nextState), .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (Self.performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state), .none)
        }
    }
}

// MARK: - Preparation

extension ClipInformationReducer {
    static func prepareQueryEffects(for id: Clip.Identity, state: State, dependency: Dependency) -> (State, [Effect<Action>]) {
        let clipQuery: ClipQuery
        switch dependency.clipQueryService.queryClip(having: id) {
        case let .success(result):
            clipQuery = result

        case .failure:
            fatalError("Failed to open clip edit view.")
        }

        let itemListQuery: ClipItemListQuery
        switch dependency.clipQueryService.queryClipItems(inClipHaving: id) {
        case let .success(result):
            itemListQuery = result

        case .failure:
            fatalError("Failed to open clip edit view.")
        }

        let tagListQuery: TagListQuery
        switch dependency.clipQueryService.queryTags(forClipHaving: id) {
        case let .success(result):
            tagListQuery = result

        case .failure:
            fatalError("Failed to open clip edit view.")
        }

        let clipStream = clipQuery.clip
            .map { Action.clipUpdated($0) as Action? }
            .catch { _ in Just(Action.clipDeleted) }
        let clipEffect = Effect(clipStream, underlying: clipQuery, completeWith: .clipDeleted)

        let itemListStream = itemListQuery.items
            .catch { _ in Just([]) }
            .map { Action.itemsUpdated($0) as Action? }
        let itemListEffect = Effect(itemListStream, underlying: itemListQuery)

        let tagListStream = tagListQuery.tags
            .catch { _ in Just([]) }
            .map { Action.tagsUpdated($0) as Action? }
        let tagListEffect = Effect(tagListStream, underlying: tagListQuery)

        let settingsStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.settingUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingsEffect = Effect(settingsStream)

        let nextState = performFilter(tags: tagListQuery.tags.value,
                                      isSomeItemsHidden: !dependency.userSettingStorage.readShowHiddenItems(),
                                      previousState: state)

        return (nextState, [clipEffect, itemListEffect, tagListEffect, settingsEffect])
    }
}

// MARK: - Filter

extension ClipInformationReducer {
    private static func performFilter(tags: [Tag],
                                      previousState: State) -> State
    {
        performFilter(tags: tags,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        performFilter(tags: previousState.tags.orderedEntities(),
                      isSomeItemsHidden: isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(tags: [Tag],
                                      isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        let newDisplayableTagIds = tags
            .filter { isSomeItemsHidden ? !$0.isHidden : true }
            .map { $0.id }
        let newTags = previousState.tags
            .updated(entities: tags.indexed())
            .updated(filteredIds: Set(newDisplayableTagIds))

        var nextState = previousState
        nextState.tags = newTags
        nextState.isSomeItemsHidden = isSomeItemsHidden

        return nextState
    }
}

private extension Clip {
    func map(to: ClipInformationState.EditingClip.Type) -> ClipInformationState.EditingClip {
        return .init(id: id,
                     dataSize: dataSize,
                     isHidden: isHidden)
    }
}
