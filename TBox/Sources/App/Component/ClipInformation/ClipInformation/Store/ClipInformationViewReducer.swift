//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit

typealias ClipInformationViewDependency = HasRouter
    & HasClipQueryService
    & HasClipCommandService
    & HasUserSettingStorage
    & HasPasteboard

struct ClipInformationViewReducer: Reducer {
    typealias Dependency = ClipInformationViewDependency
    typealias State = ClipInformationViewState
    typealias Action = ClipInformationViewAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
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
            return Self.prepare(state: nextState, dependency: dependency)

        // MARK: State Observation

        case let .clipUpdated(clip):
            return (Self.performFilter(clip: clip, previousState: state), .none)

        case let .clipItemUpdated(item):
            return (Self.performFilter(item: item, previousState: state), .none)

        case let .tagsUpdated(tags):
            return (Self.performFilter(tags: tags, previousState: state), .none)

        case let .albumsUpdated(albums):
            return (Self.performFilter(albums: albums, previousState: state), .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (Self.performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state), .none)

        case .failedToLoadClip,
             .failedToLoadClipItem,
             .failedToLoadTags,
             .failedToLoadAlbums,
             .failedToLoadSetting:
            nextState.isDismissed = true
            return (nextState, .none)

        // MARK: Control

        case .tagAdditionButtonTapped:
            nextState.modal = .tagSelection(id: UUID(), tagIds: state.tags._filteredIds)
            return (nextState, .none)

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

        case let .tagTapped(tag):
            dependency.router.routeToClipCollectionView(for: tag)
            return (nextState, .none)

        // MARK: Modal Completion

        case let .tagsSelected(tagIds):
            nextState.modal = nil

            guard let tagIds = tagIds else { return (nextState, .none) }

            switch dependency.clipCommandService.updateClips(having: [state.clipId], byReplacingTagsHaving: Array(tagIds)) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.failedToUpdateClip)
            }
            return (nextState, .none)

        case .modalCompleted:
            nextState.modal = nil
            return (nextState, .none)

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

        let albumsQuery: ListingAlbumListQuery
        switch dependency.clipQueryService.queryAlbums(containingClipHavingClipId: state.clipId) {
        case let .success(result):
            albumsQuery = result

        case let .failure(error):
            fatalError("Failed to load tags: \(error.localizedDescription)")
        }
        let albumsStream = albumsQuery.albums
            .map { Action.albumsUpdated($0) as Action? }
            .catch { _ in Just(Action.failedToLoadAlbums) }
        let albumsQueryEffect = Effect(albumsStream, underlying: albumsQuery, completeWith: .failedToLoadAlbums)

        let settingStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.settingUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingEffect = Effect(settingStream, completeWith: .failedToLoadSetting)

        // Prepare states

        let nextState = performFilter(clip: clipQuery.clip.value,
                                      item: clipItemQuery.clipItem.value,
                                      tags: tagsQuery.tags.value,
                                      albums: albumsQuery.albums.value,
                                      isSomeItemsHidden: !dependency.userSettingStorage.readShowHiddenItems(),
                                      previousState: state)

        return (nextState, [clipQueryEffect, clipItemQueryEffect, tagsQueryEffect, albumsQueryEffect, settingEffect])
    }
}

// MARK: - Filter

extension ClipInformationViewReducer {
    private static func performFilter(clip: Clip, previousState: State) -> State {
        performFilter(clip: clip,
                      item: previousState.item,
                      tags: previousState.tags.orderedEntities(),
                      albums: previousState.albums.orderedEntities(),
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(item: ClipItem, previousState: State) -> State {
        performFilter(clip: previousState.clip,
                      item: item,
                      tags: previousState.tags.orderedEntities(),
                      albums: previousState.albums.orderedEntities(),
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(tags: [Tag], previousState: State) -> State {
        performFilter(clip: previousState.clip,
                      item: previousState.item,
                      tags: tags,
                      albums: previousState.albums.orderedEntities(),
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(albums: [ListingAlbum], previousState: State) -> State {
        performFilter(clip: previousState.clip,
                      item: previousState.item,
                      tags: previousState.tags.orderedEntities(),
                      albums: albums,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool, previousState: State) -> State {
        performFilter(clip: previousState.clip,
                      item: previousState.item,
                      tags: previousState.tags.orderedEntities(),
                      albums: previousState.albums.orderedEntities(),
                      isSomeItemsHidden: isSomeItemsHidden,
                      previousState: previousState)
    }

    // swiftlint:disable:next function_parameter_count
    private static func performFilter(clip: Clip?,
                                      item: ClipItem?,
                                      tags: [Tag],
                                      albums: [ListingAlbum],
                                      isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        var nextState = previousState

        let filteredTagIds = tags
            .filter { isSomeItemsHidden ? $0.isHidden == false : true }
            .map { $0.id }

        let filteredAlbumIds = albums
            .filter { isSomeItemsHidden ? $0.isHidden == false : true }
            .map { $0.id }

        nextState.clip = clip
        nextState.item = item
        nextState.tags = nextState.tags
            .updated(entities: tags.indexed())
            .updated(filteredIds: Set(filteredTagIds))
        nextState.albums = nextState.albums
            .updated(entities: albums.indexed())
            .updated(filteredIds: Set(filteredAlbumIds))
        nextState.isSomeItemsHidden = isSomeItemsHidden

        return nextState
    }
}
