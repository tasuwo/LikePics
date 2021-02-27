//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias AlbumSelectionModalDependency = HasUserSettingStorage
    & HasClipCommandService
    & HasClipQueryService

enum AlbumSelectionModalReducer: Reducer {
    typealias Dependency = AlbumSelectionModalDependency
    typealias State = AlbumSelectionModalState
    typealias Action = AlbumSelectionModalAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return (state, prepareQueryEffects(dependency))

        // MARK: State Observation

        case let .albumsUpdated(albums):
            var nextState = performFilter(albums: albums, previousState: state)
            if nextState.shouldClearQuery {
                nextState = nextState.updating(searchQuery: "")
            }
            return (nextState, .none)

        case let .searchQueryChanged(query):
            var nextState = performFilter(searchQuery: query, previousState: state)
            if nextState.shouldClearQuery {
                nextState = nextState.updating(searchQuery: "")
            }
            return (nextState, .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state), .none)

        // MARK: Button Action

        case .emptyMessageViewActionButtonTapped, .addButtonTapped:
            return (state.updating(alert: .addition), .none)

        // MARK: Alert Completion

        case let .alertSaveButtonTapped(text: text):
            switch dependency.clipCommandService.create(albumWithTitle: text) {
            case .success:
                return (state.updating(alert: nil), .none)

            case .failure:
                return (state.updating(alert: .error(L10n.albumListViewErrorAtAddAlbum)), .none)
            }

        case .alertDismissed:
            return (state.updating(alert: nil), .none)
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
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(searchQuery: String,
                                      previousState: State) -> State
    {
        performFilter(albums: previousState._orderedAlbums,
                      searchQuery: searchQuery,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        performFilter(albums: previousState._orderedAlbums,
                      searchQuery: previousState.searchQuery,
                      isSomeItemsHidden: isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(albums: [Album],
                                      searchQuery: String,
                                      isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        var searchStorage = previousState._searchStorage

        let dict = albums.enumerated().reduce(into: [Album.Identity: Ordered<Album>]()) { dict, value in
            dict[value.element.id] = .init(index: value.offset, value: value.element)
        }

        let filteringAlbums = albums.filter { isSomeItemsHidden ? $0.isHidden == false : true }
        let filteredAlbumIds = searchStorage.perform(query: searchQuery, to: filteringAlbums).map { $0.id }

        return previousState
            .updating(searchQuery: searchQuery)
            .updating(isSomeItemsHidden: isSomeItemsHidden)
            .updating(isCollectionViewDisplaying: !filteringAlbums.isEmpty)
            .updating(isEmptyMessageViewDisplaying: filteringAlbums.isEmpty)
            .updating(_filteredAlbumIds: Set(filteredAlbumIds))
            .updating(_albums: dict)
            .updating(_searchStorage: searchStorage)
    }
}

private extension AlbumSelectionModalState {
    var shouldClearQuery: Bool { _albums.isEmpty && !searchQuery.isEmpty }
}
