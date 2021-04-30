//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias ClipInformationViewDependency = HasRouter
    & HasClipQueryService
    & HasClipCommandService
    & HasUserSettingStorage
    & HasPasteboard

enum ClipInformationViewReducer: Reducer {
    typealias Dependency = ClipInformationViewDependency
    typealias State = ClipInformationViewState
    typealias Action = ClipInformationViewAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        switch action {
        // MARK: View Life-Cycle

        case .viewWillAppear:
            nextState.isHiddenStatusBar = true
            return (nextState, .none)

        case .viewDidAppear:
            nextState.shouldCollectionViewUpdateWithAnimation = true
            nextState.isSuspendedCollectionViewUpdate = false
            return (nextState, .none)

        case .viewWillDisappear:
            nextState.isHiddenStatusBar = false
            return (nextState, .none)

        case .viewDidLoad:
            nextState.shouldCollectionViewUpdateWithAnimation = false
            nextState.isSuspendedCollectionViewUpdate = true
            return prepare(state: nextState, dependency: dependency)

        // MARK: State Observation

        case let .clipUpdated(clip):
            return (performFilter(clip: clip, previousState: state), .none)

        case let .clipItemUpdated(item):
            return (performFilter(item: item, previousState: state), .none)

        case let .tagsUpdated(tags):
            return (performFilter(tags: tags, previousState: state), .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state), .none)

        case .failedToLoadClip,
             .failedToLoadClipItem,
             .failedToLoadTags,
             .failedToLoadSetting:
            nextState.isDismissed = true
            return (nextState, .none)

        // MARK: Control

        case .tagAdditionButtonTapped:
            let effect = showTagSelectionModal(selections: Set(state.tags._displayableIds), dependency: dependency)
            return (nextState, [effect])

        case let .tagRemoveButtonTapped(tagId):
            if case .failure = dependency.clipCommandService.updateClips(having: [state.clipId], byDeletingTagsHaving: [tagId]) {
                nextState.alert = .error(L10n.clipInformationErrorAtRemoveTags)
            }
            return (nextState, .none)

        case .siteUrlEditButtonTapped:
            nextState.alert = .siteUrlEdit(title: state.item?.url?.absoluteString)
            return (nextState, .none)

        case .hidedClip:
            if case .failure = dependency.clipCommandService.updateClips(having: [state.clipId], byHiding: true) {
                nextState.alert = .error(L10n.clipInformationErrorAtUpdateHidden)
            }
            return (nextState, .none)

        case .revealedClip:
            if case .failure = dependency.clipCommandService.updateClips(having: [state.clipId], byHiding: false) {
                nextState.alert = .error(L10n.clipInformationErrorAtUpdateHidden)
            }
            return (nextState, .none)

        case let .urlOpenMenuSelected(url):
            if let url = url { dependency.router.open(url) }
            return (nextState, .none)

        case let .urlCopyMenuSelected(url):
            if let url = url { dependency.pasteboard.set(url.absoluteString) }
            return (nextState, .none)

        // MARK: Modal Completion

        case let .tagsSelected(tagIds):
            guard let tagIds = tagIds else { return (state, .none) }
            switch dependency.clipCommandService.updateClips(having: [state.clipId], byReplacingTagsHaving: Array(tagIds)) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.failedToUpdateClip)
            }
            return (nextState, .none)

        case .modalCompleted:
            return (state, .none)

        // MARK: Alert Completion

        case let .siteUrlEditConfirmed(text):
            if case .failure = dependency.clipCommandService.updateClipItems(having: [state.itemId], byUpdatingSiteUrl: URL(string: text)) {
                nextState.alert = .error(L10n.clipInformationErrorAtUpdateSiteUrl)
            }
            nextState.alert = nil
            return (nextState, .none)

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension ClipInformationViewReducer {
    static func prepare(state: State, dependency: Dependency) -> (State, [Effect<Action>]) {
        // Prepare effects

        let clipQuery: ClipQuery
        switch dependency.clipQueryService.queryClip(having: state.clipId) {
        case let .success(result):
            clipQuery = result

        case let .failure(error):
            fatalError("Failed to load clips: \(error.localizedDescription)")
        }
        let clipStream = clipQuery.clip
            .map { Action.clipUpdated($0) as Action? }
            .catch { _ in Just(Action.failedToLoadClip) }
        let clipQueryEffect = Effect(clipStream, underlying: clipQuery, completeWith: .failedToLoadClip)

        let clipItemQuery: ClipItemQuery
        switch dependency.clipQueryService.queryClipItem(having: state.itemId) {
        case let .success(result):
            clipItemQuery = result

        case let .failure(error):
            fatalError("Failed to load items: \(error.localizedDescription)")
        }
        let clipItemStream = clipItemQuery.clipItem
            .map { Action.clipItemUpdated($0) as Action? }
            .catch { _ in Just(Action.failedToLoadClipItem) }
        let clipItemQueryEffect = Effect(clipItemStream, underlying: clipItemQuery, completeWith: .failedToLoadClipItem)

        let tagsQuery: TagListQuery
        switch dependency.clipQueryService.queryTags(forClipHaving: state.clipId) {
        case let .success(result):
            tagsQuery = result

        case let .failure(error):
            fatalError("Failed to load tags: \(error.localizedDescription)")
        }
        let tagsStream = tagsQuery.tags
            .map { Action.tagsUpdated($0) as Action? }
            .catch { _ in Just(Action.failedToLoadTags) }
        let tagsQueryEffect = Effect(tagsStream, underlying: tagsQuery, completeWith: .failedToLoadTags)

        let settingStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.settingUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingEffect = Effect(settingStream, completeWith: .failedToLoadSetting)

        // Prepare states

        let nextState = performFilter(clip: clipQuery.clip.value,
                                      item: clipItemQuery.clipItem.value,
                                      tags: tagsQuery.tags.value,
                                      isSomeItemsHidden: !dependency.userSettingStorage.readShowHiddenItems(),
                                      previousState: state)

        return (nextState, [clipQueryEffect, clipItemQueryEffect, tagsQueryEffect, settingEffect])
    }
}

// MARK: - Filter

extension ClipInformationViewReducer {
    private static func performFilter(clip: Clip, previousState: State) -> State {
        performFilter(clip: clip,
                      item: previousState.item,
                      tags: previousState.tags.orderedValues,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(item: ClipItem, previousState: State) -> State {
        performFilter(clip: previousState.clip,
                      item: item,
                      tags: previousState.tags.orderedValues,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(tags: [Tag], previousState: State) -> State {
        performFilter(clip: previousState.clip,
                      item: previousState.item,
                      tags: tags,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool, previousState: State) -> State {
        performFilter(clip: previousState.clip,
                      item: previousState.item,
                      tags: previousState.tags.orderedValues,
                      isSomeItemsHidden: isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(clip: Clip?,
                                      item: ClipItem?,
                                      tags: [Tag],
                                      isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        var nextState = previousState

        let filteredTagIds = tags
            .filter { isSomeItemsHidden ? $0.isHidden == false : true }
            .map { $0.id }

        nextState.clip = clip
        nextState.item = item
        nextState.tags = nextState.tags
            .updated(_values: tags.indexed())
            .updated(_displayableIds: Set(filteredTagIds))
        nextState.isSomeItemsHidden = isSomeItemsHidden

        return nextState
    }
}

// MARK: - Router

extension ClipInformationViewReducer {
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
