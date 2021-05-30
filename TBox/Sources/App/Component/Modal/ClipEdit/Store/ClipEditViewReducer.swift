//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit

typealias ClipEditViewDependency = HasRouter
    & HasClipCommandService
    & HasClipQueryService
    & HasUserSettingStorage
    & HasPasteboard
    & HasModalNotificationCenter

struct ClipEditViewReducer: Reducer {
    typealias Dependency = ClipEditViewDependency
    typealias State = ClipEditViewState
    typealias Action = ClipEditViewAction

    // swiftlint:disable:next function_body_length
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
            return Self.dismiss(state: state, dependency: dependency)

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

        // MARK: NavigationBar

        case .doneButtonTapped:
            return Self.dismiss(state: state, dependency: dependency)

        // MARK: Button/Switch Action

        case .tagAdditionButtonTapped:
            nextState.modal = .tagSelection(id: UUID(), tagIds: state.tags._filteredIds)
            return (nextState, .none)

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
            nextState.items = state.items.updated(selectedIds: .init())
            return (nextState, .none)

        case .itemsEditCancelButtonTapped:
            nextState.isItemsEditing = false
            nextState.items = state.items.updated(selectedIds: .init())
            return (nextState, .none)

        case .itemsSiteUrlsEditButtonTapped:
            guard !state.items.selectedIds().isEmpty else { return (state, .none) }
            nextState.alert = .siteUrlEdit(itemIds: state.items.selectedIds(), title: nil)
            return (nextState, .none)

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
                .compactMap { state.items.entity(having: $0) }
                .indexed()
            nextState.items = state.items.updated(entities: newValues)
            return (nextState, [Effect(stream)])

        case .itemsReorderFailed:
            nextState.alert = .error(L10n.failedToUpdateClip)
            return (nextState, .none)

        case let .itemSiteUrlEditButtonTapped(itemId):
            guard let item = state.items.entity(having: itemId) else { return (state, .none) }
            nextState.alert = .siteUrlEdit(itemIds: Set([itemId]), title: item.url?.absoluteString)
            return (nextState, .none)

        case let .itemSiteUrlButtonTapped(url):
            guard let url = url else { return (state, .none) }
            dependency.router.open(url)
            return (state, .none)

        case let .itemDeletionActionOccurred(itemId, completion: completion):
            guard let item = state.items.entity(having: itemId) else {
                completion(false)
                return (state, .none)
            }

            guard case .success = dependency.clipCommandService.deleteClipItem(item) else {
                completion(false)
                return (state, .none)
            }

            nextState.items = state.items.removingEntity(having: itemId)

            return (nextState, .none)

        case let .itemSelected(itemId):
            guard !state.items._selectedIds.contains(itemId) else { return (state, .none) }
            let newSelections = state.items._selectedIds.union([itemId])
            nextState.items = state.items.updated(selectedIds: newSelections)
            return (nextState, .none)

        case let .itemDeselected(itemId):
            guard state.items._selectedIds.contains(itemId) else { return (state, .none) }
            let newSelections = state.items._selectedIds.subtracting([itemId])
            nextState.items = state.items.updated(selectedIds: newSelections)
            return (nextState, .none)

        case .clipDeletionButtonTapped:
            nextState.alert = .deleteConfirmation
            return (nextState, .none)

        // MARK: Context Menu

        case let .siteUrlOpenMenuTapped(itemId):
            guard let item = state.items.entity(having: itemId), let url = item.url else { return (state, .none) }
            dependency.router.open(url)
            return (state, .none)

        case let .siteUrlCopyMenuTapped(itemId):
            guard let item = state.items.entity(having: itemId), let url = item.url else { return (state, .none) }
            dependency.pasteboard.set(url.absoluteString)
            return (state, .none)

        // MARK: Modal Completion

        case let .tagsSelected(tagIds):
            nextState.modal = nil

            guard let tagIds = tagIds else { return (nextState, .none) }

            switch dependency.clipCommandService.updateClips(having: [state.clip.id], byReplacingTagsHaving: Array(tagIds)) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.failedToUpdateClip)
            }
            return (nextState, .none)

        case .modalCompleted:
            nextState.modal = nil
            return (nextState, .none)

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
                nextState.items = state.items.updated(selectedIds: .init())

            case .failure:
                nextState.alert = .error(L10n.failedToUpdateClip)
            }
            return (nextState, .none)

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)

        // MARK: Transition

        case .didDismissedManually:
            return Self.dismiss(state: state, dependency: dependency)
        }
    }
}

// MARK: - Preparation

extension ClipEditViewReducer {
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
    func map(to: ClipEditViewState.EditingClip.Type) -> ClipEditViewState.EditingClip {
        return .init(id: id,
                     dataSize: dataSize,
                     isHidden: isHidden)
    }
}

// MARK: - Dismiss

extension ClipEditViewReducer {
    private static func dismiss(state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        dependency.modalNotificationCenter.post(id: state.id, name: .clipEditModal)
        nextState.isDismissed = true
        return (nextState, .none)
    }
}

// MARK: - ModalNotification

extension ModalNotification.Name {
    static let clipEditModal = ModalNotification.Name("net.tasuwo.TBox.ClipEditViewReducer.clipEditModal")
}
