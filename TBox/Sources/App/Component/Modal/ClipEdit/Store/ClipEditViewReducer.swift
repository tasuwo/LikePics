//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias ClipEditViewDependency = HasRouter
    & HasClipCommandService
    & HasClipQueryService
    & HasUserSettingStorage
    & HasPasteboard

enum ClipEditViewReducer: Reducer {
    typealias Dependency = ClipEditViewDependency
    typealias State = ClipEditViewState
    typealias Action = ClipEditViewAction

    // swiftlint:disable:next function_body_length
    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            let effects = prepareQueryEffects(for: state.clip.id, with: dependency)
            return (nextState, effects)

        // MARK: State Observation

        case let .clipUpdated(clip):
            nextState.clip = clip.map(to: State.EditingClip.self)
            return (nextState, .none)

        case .clipDeleted:
            nextState.isDismissed = true
            return (nextState, .none)

        case let .itemsUpdated(items):
            let newItems = state.items
                .updated(_values: items.indexed())
                .updated(_displayableIds: Set(items.map({ $0.identity })))
            nextState.items = newItems
            return (nextState, .none)

        case let .tagsUpdated(tags):
            return (performFilter(tags: tags, previousState: nextState), .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state), .none)

        // MARK: NavigationBar

        case .doneButtonTapped:
            nextState.isDismissed = true
            return (nextState, .none)

        // MARK: Button/Switch Action

        case .tagAdditionButtonTapped:
            let effect = showTagSelectionModal(selections: Set(state.tags._displayableIds), dependency: dependency)
            return (nextState, [effect])

        case let .tagDeletionButtonTapped(tagId):
            switch dependency.clipCommandService.updateClips(having: [state.clip.id], byDeletingTagsHaving: [tagId]) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.failedToUpdateClip)
            }
            return (nextState, .none)

        case let .clipHidesSwitchChanged(isOn: isOn):
            switch dependency.clipCommandService.updateClips(having: [state.clip.id], byHiding: isOn) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.failedToUpdateClip)
            }
            return (nextState, .none)

        case .itemsEditButtonTapped:
            nextState.isItemsEditing = true
            nextState.items = state.items.updated(_selectedIds: .init())
            return (nextState, .none)

        case .itemsEditCancelButtonTapped:
            nextState.isItemsEditing = false
            nextState.items = state.items.updated(_selectedIds: .init())
            return (nextState, .none)

        case .itemsSiteUrlsEditButtonTapped:
            guard !state.items._validSelections.isEmpty else { return (state, .none) }
            nextState.alert = .siteUrlEdit(itemIds: state.items._validSelections, title: nil)
            return (nextState, .none)

        case let .itemsReordered(itemIds):
            assert(itemIds.count == state.items._values.values.count)
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
                .compactMap { state.items._values[$0]?.value }
                .indexed()
            nextState.items = state.items.updated(_values: newValues)
            return (nextState, [Effect(stream)])

        case .itemsReorderFailed:
            nextState.alert = .error(L10n.failedToUpdateClip)
            return (nextState, .none)

        case let .itemSiteUrlEditButtonTapped(itemId):
            guard let item = state.items._values[itemId]?.value else { return (state, .none) }
            nextState.alert = .siteUrlEdit(itemIds: Set([itemId]), title: item.url?.absoluteString)
            return (nextState, .none)

        case let .itemSiteUrlButtonTapped(url):
            guard let url = url else { return (state, .none) }
            dependency.router.open(url)
            return (state, .none)

        case let .itemDeletionActionOccurred(itemId, completion: completion):
            guard let item = state.items._values[itemId]?.value else {
                completion(false)
                return (state, .none)
            }

            guard case .success = dependency.clipCommandService.deleteClipItem(item) else {
                completion(false)
                return (state, .none)
            }

            var newItemsValues = state.items._values
            newItemsValues.removeValue(forKey: item.id)
            nextState.items = state.items.updated(_values: newItemsValues)

            return (nextState, .none)

        case let .itemSelected(itemId):
            guard !state.items._selectedIds.contains(itemId) else { return (state, .none) }
            let newSelections = state.items._selectedIds.union([itemId])
            nextState.items = state.items.updated(_selectedIds: newSelections)
            return (nextState, .none)

        case let .itemDeselected(itemId):
            guard state.items._selectedIds.contains(itemId) else { return (state, .none) }
            let newSelections = state.items._selectedIds.subtracting([itemId])
            nextState.items = state.items.updated(_selectedIds: newSelections)
            return (nextState, .none)

        case let .clipDeletionButtonTapped(indexPath):
            nextState.alert = .deleteConfirmation(indexPath)
            return (nextState, .none)

        // MARK: Context Menu

        case let .siteUrlOpenMenuTapped(itemId):
            guard let item = state.items._values[itemId]?.value, let url = item.url else { return (state, .none) }
            dependency.router.open(url)
            return (state, .none)

        case let .siteUrlCopyMenuTapped(itemId):
            guard let item = state.items._values[itemId]?.value, let url = item.url else { return (state, .none) }
            dependency.pasteboard.set(url.absoluteString)
            return (state, .none)

        // MARK: Modal Completion

        case let .tagsSelected(tagIds):
            guard let tagIds = tagIds else { return (state, .none) }
            switch dependency.clipCommandService.updateClips(having: [state.clip.id], byReplacingTagsHaving: Array(tagIds)) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.failedToUpdateClip)
            }
            return (nextState, .none)

        case .modalCompleted:
            return (state, .none)

        // MARK: Alert Completion

        case .clipDeleteConfirmed:
            switch dependency.clipCommandService.deleteClips(having: [state.clip.id]) {
            case .success:
                nextState.alert = nil

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtDeleteClip)
            }
            return (nextState, .none)

        case let .siteUrlEditConfirmed(text: text):
            guard case let .siteUrlEdit(itemIds: itemIds, title: _) = state.alert else {
                nextState.alert = nil
                return (nextState, .none)
            }
            switch dependency.clipCommandService.updateClipItems(having: Array(itemIds), byUpdatingSiteUrl: URL(string: text)) {
            case .success:
                nextState.alert = nil
                nextState.isItemsEditing = false
                nextState.items = state.items.updated(_selectedIds: .init())

            case .failure:
                nextState.alert = .error(L10n.failedToUpdateClip)
            }
            return (nextState, .none)

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)

        // MARK: Transition

        case .didDismissedManually:
            nextState.isDismissed = true
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension ClipEditViewReducer {
    static func prepareQueryEffects(for id: Clip.Identity, with dependency: Dependency) -> [Effect<Action>] {
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

        return [clipEffect, itemListEffect, tagListEffect, settingsEffect]
    }
}

// MARK: - Filter

extension ClipEditViewReducer {
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
        performFilter(tags: previousState.tags.orderedValues,
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
            .updated(_values: tags.indexed())
            .updated(_displayableIds: Set(newDisplayableTagIds))

        var nextState = previousState
        nextState.tags = newTags
        nextState.isSomeItemsHidden = isSomeItemsHidden

        return nextState
    }
}

// MARK: - Router

extension ClipEditViewReducer {
    static func showTagSelectionModal(selections: Set<Tag.Identity>, dependency: HasRouter) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                let isPresented = dependency.router.showTagSelectionModal(selections: selections) { tags in
                    guard let tagIds = tags?.map({ $0.id }) else {
                        promise(.success(.modalCompleted(false)))
                        return
                    }
                    promise(.success(.tagsSelected(Set(tagIds))))
                }
                if !isPresented {
                    promise(.success(.modalCompleted(false)))
                }
            }
        }
        return Effect(stream)
    }
}

private extension Clip {
    func map(to: ClipEditViewState.EditingClip.Type) -> ClipEditViewState.EditingClip {
        return .init(id: id,
                     dataSize: dataSize,
                     isHidden: isHidden)
    }
}
