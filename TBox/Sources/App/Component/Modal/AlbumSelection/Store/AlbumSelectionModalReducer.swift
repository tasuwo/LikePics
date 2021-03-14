//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias AlbumSelectionModalDependency = HasUserSettingStorage
    & HasClipCommandService
    & HasClipQueryService
    & HasAlbumSelectionModalSubscription

enum AlbumSelectionModalReducer: Reducer {
    typealias Dependency = AlbumSelectionModalDependency
    typealias State = AlbumSelectionModalState
    typealias Action = AlbumSelectionModalAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return (nextState, prepareQueryEffects(dependency))

        case .viewDidDisappear:
            dependency.albumSelectionCompleted(nextState.selectedAlbumId)
            return (nextState, .none)

        // MARK: State Observation

        case let .albumsUpdated(albums):
            nextState = performFilter(albums: albums, previousState: nextState)
            return (nextState, .none)

        case let .searchQueryChanged(query):
            nextState = performFilter(searchQuery: query, previousState: nextState)
            return (nextState, .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: nextState), .none)

        // MARK: Button Action

        case let .selected(albumId):
            nextState.selectedAlbumId = albumId
            nextState.isDismissed = true
            return (nextState, .none)

        case .emptyMessageViewActionButtonTapped, .addButtonTapped:
            nextState.alert = .addition
            return (nextState, .none)

        // MARK: Alert Completion

        case let .alertSaveButtonTapped(text: text):
            switch dependency.clipCommandService.create(albumWithTitle: text) {
            case .success:
                nextState.alert = nil

            case .failure:
                nextState.alert = .error(L10n.albumListViewErrorAtAddAlbum)
            }
            return (nextState, .none)

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension AlbumSelectionModalReducer {
    static func prepareQueryEffects(_ dependency: Dependency) -> [Effect<Action>] {
        let query: AlbumListQuery
        switch dependency.clipQueryService.queryAllAlbums() {
        case let .success(result):
            query = result

        case let .failure(error):
            fatalError("Failed to load albums: \(error.localizedDescription)")
        }

        let albumsStream = query.albums
            .catch { _ in Just([]) }
            .map { Action.albumsUpdated($0) as Action? }
        let albumsEffect = Effect(albumsStream, underlying: query)

        let settingsStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.settingUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingsEffect = Effect(settingsStream)

        return [albumsEffect, settingsEffect]
    }
}

// MARK: - Filter

extension AlbumSelectionModalReducer {
    private static func performFilter(albums: [Album],
                                      previousState: State) -> State
    {
        performFilter(albums: albums,
                      searchQuery: previousState.searchQuery,
                      isSomeItemsHidden: previousState._isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(searchQuery: String,
                                      previousState: State) -> State
    {
        performFilter(albums: previousState.albums.orderedValues,
                      searchQuery: searchQuery,
                      isSomeItemsHidden: previousState._isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        performFilter(albums: previousState.albums.orderedValues,
                      searchQuery: previousState.searchQuery,
                      isSomeItemsHidden: isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(albums: [Album],
                                      searchQuery: String,
                                      isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        var nextState = previousState
        var searchStorage = previousState._searchStorage

        let filteringAlbums = albums.filter { isSomeItemsHidden ? $0.isHidden == false : true }
        let filteredAlbumIds = searchStorage.perform(query: searchQuery, to: filteringAlbums).map { $0.id }
        let newAlbums = previousState.albums
            .updated(_values: albums.indexed())
            .updated(_displayableIds: Set(filteredAlbumIds))
        nextState.albums = newAlbums

        nextState.searchQuery = searchQuery
        nextState._isSomeItemsHidden = isSomeItemsHidden
        nextState.isCollectionViewDisplaying = !filteringAlbums.isEmpty
        nextState.isEmptyMessageViewDisplaying = filteringAlbums.isEmpty
        nextState._searchStorage = searchStorage

        if filteringAlbums.isEmpty, !searchQuery.isEmpty {
            nextState.searchQuery = ""
        }

        return nextState
    }
}
