//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit

typealias ClipItemListDependency = HasClipQueryService
    & HasClipCommandService
    & HasUserSettingStorage
    & HasRouter
    & HasPasteboard

struct ClipItemListReducer: Reducer {
    typealias Dependency = ClipItemListDependency
    typealias State = ClipItemListState
    typealias Action = ClipItemListAction

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

        // MARK: Operation

        case let .reordered(itemIds):
            let stream = Deferred {
                Future<Action?, Never> { promise in
                    DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                        switch dependency.clipCommandService.updateClip(having: state.clip.id, byReorderingItemsHaving: itemIds) {
                        case .success:
                            promise(.success(nil))

                        case .failure:
                            promise(.success(.itemsReorderFailed))
                        }
                    }
                }
            }
            let newValues = itemIds
                .compactMap { state.items.entity(having: $0) }
                .indexed()
            nextState.items = state.items.updated(entities: newValues)
            return (nextState, [Effect(stream)])

        case let .selected(itemId):
            dependency.router.showClipPreviewView(for: state.clip.id, at: itemId)
            return (nextState, .none)

        case .itemsReorderFailed:
            nextState.alert = .error(L10n.failedToUpdateClip)
            return (nextState, .none)

        // MARK: Menu

        case let .deleteMenuTapped(itemId):
            guard let item = state.items.entity(having: itemId) else { return (nextState, .none) }
            nextState.alert = .deletion(item)
            return (nextState, .none)

        case let .copyImageUrlMenuTapped(itemId):
            guard let item = state.items.entity(having: itemId),
                  let imageUrl = item.imageUrl else { return (nextState, .none) }
            dependency.pasteboard.set(imageUrl.absoluteString)
            return (nextState, .none)

        case let .openImageUrlMenuTapped(itemId):
            guard let item = state.items.entity(having: itemId),
                  let imageUrl = item.imageUrl else { return (nextState, .none) }
            dependency.router.open(imageUrl)
            return (nextState, .none)

        // MARK: Alert Completion

        case .alertDeleteConfirmed:
            guard case let .deletion(storedItem) = state.alert,
                  let item = state.items.entity(having: storedItem.id)
            else {
                nextState.alert = nil
                return (nextState, .none)
            }
            switch dependency.clipCommandService.deleteClipItem(item) {
            case .success:
                nextState.alert = nil

            case .failure:
                nextState.alert = .error(L10n.errorAtDeleteClipItem)
            }
            return (nextState, .none)

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension ClipItemListReducer {
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

extension ClipItemListReducer {
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

extension ClipItemListReducer {
    private static func performReorder(originals: [ClipItem.Identity], request: [ClipItem.Identity]) -> [ClipItem.Identity] {
        var index = 0
        return originals
            .map { original in
                guard request.contains(original) else { return original }
                index += 1
                return request[index - 1]
            }
    }
}

private extension Clip {
    func map(to: ClipItemListState.EditingClip.Type) -> ClipItemListState.EditingClip {
        return .init(id: id,
                     dataSize: dataSize,
                     isHidden: isHidden)
    }
}
