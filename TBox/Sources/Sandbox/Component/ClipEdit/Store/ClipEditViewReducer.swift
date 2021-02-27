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

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            let effects = prepareQueryEffects(for: state.clip.id, with: dependency)
            return (state, effects)

        // MARK: State Observation

        case let .clipUpdated(clip):
            return (state.updating(clip: clip.map(to: State.EditingClip.self)), .none)

        case .clipDeleted:
            return (state.updating(isDismissed: true), .none)

        case let .itemsUpdated(items):
            let newItems = state.items
                .updated(_values: items.indexed())
                .updated(_displayableIds: Set(items.map({ $0.identity })))
            return (state.updating(items: newItems), .none)

        case let .tagsUpdated(tags):
            return (performFilter(tags: tags, previousState: state), .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state), .none)

        // MARK: NavigationBar

        case .doneButtonTapped:
            return (state.updating(isDismissed: true), .none)

        // MARK: Button/Switch Action

        case .tagAdditionButtonTapped:
            let effect = showTagSelectionModal(selections: Set(state.tags._selectedIds), dependency: dependency)
            return (state, [effect])

        case let .tagDeletionButtonTapped(tagId):
            switch dependency.clipCommandService.updateClips(having: [state.clip.id], byDeletingTagsHaving: [tagId]) {
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.failedToUpdateClip)), .none)
            }

        case let .clipHidesSwitchChanged(isOn: isOn):
            switch dependency.clipCommandService.updateClips(having: [state.clip.id], byHiding: isOn) {
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.failedToUpdateClip)), .none)
            }

        case .itemsEditButtonTapped:
            let newState = state
                .updating(isItemsEditing: true)
                .updating(items: state.items.updated(_selectedIds: .init()))
            return (newState, .none)

        case .itemsEditCancelButtonTapped:
            let newState = state
                .updating(isItemsEditing: false)
                .updating(items: state.items.updated(_selectedIds: .init()))
            return (newState, .none)

        case .itemsSiteUrlsEditButtonTapped:
            guard !state.items._validSelections.isEmpty else { return (state, .none) }
            return (state.updating(alert: .siteUrlEdit(itemIds: state.items._validSelections, title: nil)), .none)

        case let .itemsReordered(itemIds):
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
                .enumerated()
                .reduce(into: [ClipItem.Identity: Ordered<ClipItem>]()) { dict, keyValue in
                    dict[keyValue.element.id] = .init(index: keyValue.offset, value: keyValue.element)
                }
            return (state.updating(items: state.items.updated(_values: newValues)), [Effect(stream)])

        case .itemsReorderFailed:
            return (state.updating(alert: .error(L10n.failedToUpdateClip)), .none)

        case let .itemSiteUrlEditButtonTapped(itemId):
            guard let item = state.items._values[itemId]?.value else { return (state, .none) }
            return (state.updating(alert: .siteUrlEdit(itemIds: Set([itemId]), title: item.url?.absoluteString)), .none)

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
            let newState = state
                .updating(items: state.items.updated(_values: newItemsValues))

            return (newState, .none)

        case let .itemSelected(itemId):
            guard !state.items._selectedIds.contains(itemId) else { return (state, .none) }
            let newSelections = state.items._selectedIds.union([itemId])
            return (state.updating(items: state.items.updated(_selectedIds: newSelections)), .none)

        case let .itemDeselected(itemId):
            guard state.items._selectedIds.contains(itemId) else { return (state, .none) }
            let newSelections = state.items._selectedIds.subtracting([itemId])
            return (state.updating(items: state.items.updated(_selectedIds: newSelections)), .none)

        case .clipDeletionButtonTapped:
            switch dependency.clipCommandService.deleteClips(having: [state.clip.id]) {
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtDeleteClip)), .none)
            }

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
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.failedToUpdateClip)), .none)
            }

        case .modalCompleted:
            return (state, .none)

        // MARK: Alert Completion

        case let .siteUrlEditConfirmed(text: text):
            guard case let .siteUrlEdit(itemIds: itemIds, title: _) = state.alert else { return (state.updating(alert: nil), .none) }
            switch dependency.clipCommandService.updateClipItems(having: Array(itemIds), byUpdatingSiteUrl: URL(string: text)) {
            case .success:
                return (state.updating(alert: nil), .none)

            case .failure:
                return (state.updating(alert: .error(L10n.failedToUpdateClip)), .none)
            }

        case .alertDismissed:
            return (state.updating(alert: nil), .none)

        // MARK: Transition

        case .didDismissedManually:
            return (state.updating(isDismissed: true), .none)
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
        performFilter(tags: tags, isSomeItemsHidden: previousState.isSomeItemsHidden, previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        performFilter(tags: previousState.tags.orderedValues, isSomeItemsHidden: isSomeItemsHidden, previousState: previousState)
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

        let newState = previousState
            .updating(tags: newTags)
            .updating(isSomeItemsHidden: isSomeItemsHidden)

        return newState
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

extension Clip {
    func map(to: ClipEditViewState.EditingClip.Type) -> ClipEditViewState.EditingClip {
        return .init(id: id,
                     dataSize: dataSize,
                     isHidden: isHidden)
    }
}
