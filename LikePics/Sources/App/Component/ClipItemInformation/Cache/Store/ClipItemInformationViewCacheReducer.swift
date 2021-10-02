//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit

typealias ClipItemInformationViewCacheDependency = HasClipQueryService
    & HasUserSettingStorage

struct ClipItemInformationViewCacheReducer: Reducer {
    typealias Dependency = ClipItemInformationViewCacheDependency
    typealias State = ClipItemInformationViewCacheState
    typealias Action = ClipItemInformationViewCacheAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        switch action {
        // MARK: Life-Cycle

        case let .pageChanged(clipId: clipId, itemId: itemId):
            nextState.clipId = clipId
            nextState.itemId = itemId
            return (nextState, nil)

        case let .load(clipId: clipId, itemId: itemId):
            nextState = nextState.cleared()
            return Self.prepare(clipId: clipId, itemId: itemId, state: nextState, dependency: dependency)

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
            nextState.isInvalidated = true
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension ClipItemInformationViewCacheReducer {
    static func prepare(clipId: Clip.Identity,
                        itemId: ClipItem.Identity,
                        state: State,
                        dependency: Dependency) -> (State, [Effect<Action>])
    {
        // Prepare effects

        let clipQuery: ClipQuery
        switch dependency.clipQueryService.queryClip(having: clipId) {
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
        switch dependency.clipQueryService.queryClipItem(having: itemId) {
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
        switch dependency.clipQueryService.queryTags(forClipHaving: clipId) {
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
        switch dependency.clipQueryService.queryAlbums(containingClipHavingClipId: clipId) {
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

extension ClipItemInformationViewCacheReducer {
    private static func performFilter(clip: Clip, previousState: State) -> State {
        performFilter(clip: clip,
                      item: previousState.information?.item,
                      tags: previousState.information?.tags.orderedEntities(),
                      albums: previousState.information?.albums.orderedEntities(),
                      isSomeItemsHidden: previousState.information?.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(item: ClipItem, previousState: State) -> State {
        performFilter(clip: previousState.information?.clip,
                      item: item,
                      tags: previousState.information?.tags.orderedEntities(),
                      albums: previousState.information?.albums.orderedEntities(),
                      isSomeItemsHidden: previousState.information?.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(tags: [Tag], previousState: State) -> State {
        performFilter(clip: previousState.information?.clip,
                      item: previousState.information?.item,
                      tags: tags,
                      albums: previousState.information?.albums.orderedEntities(),
                      isSomeItemsHidden: previousState.information?.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(albums: [ListingAlbum], previousState: State) -> State {
        performFilter(clip: previousState.information?.clip,
                      item: previousState.information?.item,
                      tags: previousState.information?.tags.orderedEntities(),
                      albums: albums,
                      isSomeItemsHidden: previousState.information?.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool, previousState: State) -> State {
        performFilter(clip: previousState.information?.clip,
                      item: previousState.information?.item,
                      tags: previousState.information?.tags.orderedEntities(),
                      albums: previousState.information?.albums.orderedEntities(),
                      isSomeItemsHidden: isSomeItemsHidden,
                      previousState: previousState)
    }

    // swiftlint:disable:next function_parameter_count
    private static func performFilter(clip: Clip?,
                                      item: ClipItem?,
                                      tags: [Tag]?,
                                      albums: [ListingAlbum]?,
                                      isSomeItemsHidden: Bool?,
                                      previousState: State) -> State
    {
        var nextState = previousState
        var information = previousState.information ?? ClipItemInformationViewCacheState.Information()

        let tags = tags ?? []
        let albums = albums ?? []
        let isSomeItemsHidden = isSomeItemsHidden ?? true

        let filteredTagIds = tags
            .filter { isSomeItemsHidden ? $0.isHidden == false : true }
            .map { $0.id }
        let filteredAlbumIds = albums
            .filter { isSomeItemsHidden ? $0.isHidden == false : true }
            .map { $0.id }

        information.clip = clip
        information.item = item
        information.tags = nextState.information?.tags
            .updated(entities: tags)
            .updated(filteredIds: Set(filteredTagIds)) ?? .init()
        information.albums = nextState.information?.albums
            .updated(entities: albums)
            .updated(filteredIds: Set(filteredAlbumIds)) ?? .init()
        information.isSomeItemsHidden = isSomeItemsHidden

        nextState.information = information

        return nextState
    }
}
