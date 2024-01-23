//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import Environment

public typealias AlbumSelectionModalDependency = HasClipCommandService
    & HasClipQueryService
    & HasModalNotificationCenter
    & HasUserSettingStorage

public struct AlbumSelectionModalReducer: Reducer {
    public typealias Dependency = AlbumSelectionModalDependency
    public typealias State = AlbumSelectionModalState
    public typealias Action = AlbumSelectionModalAction

    public func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return Self.prepareQueryEffects(nextState, dependency)

        case .viewDidDisappear:
            var userInfo: [ModalNotification.UserInfoKey: Any] = [:]
            userInfo[.selectedAlbumId] = state.selectedAlbumId
            dependency.modalNotificationCenter.post(id: state.id, name: .albumSelectionModal, userInfo: userInfo)
            return (nextState, .none)

        // MARK: State Observation

        case let .albumsUpdated(albums):
            nextState = Self.performFilter(albums: albums, previousState: nextState)
            return (nextState, .none)

        case let .searchQueryChanged(query):
            nextState = Self.performFilter(searchQuery: query, previousState: nextState)
            return (nextState, .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (Self.performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: nextState), .none)

        // MARK: Button Action

        case let .selected(albumId):
            nextState.selectedAlbumId = albumId
            nextState.isDismissed = true
            return (nextState, .none)

        case .emptyMessageViewActionButtonTapped, .addButtonTapped:
            nextState.alert = .addition
            return (nextState, .none)

        case .quickAddButtonTapped:
            switch dependency.clipCommandService.create(albumWithTitle: state.searchQuery) {
            case .success:
                nextState.alert = nil

            case .failure:
                nextState.alert = .error(L10n.albumListViewErrorAtAddAlbum)
            }
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

        // MARK: Transition

        case .didDismissedManually:
            dependency.modalNotificationCenter.post(id: state.id, name: .albumSelectionModalDidDismiss, userInfo: nil)
            nextState.isDismissed = true
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension AlbumSelectionModalReducer {
    static func prepareQueryEffects(_ state: State, _ dependency: Dependency) -> (State, [Effect<Action>]) {
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

        let nextState = performFilter(albums: query.albums.value,
                                      searchQuery: state.searchQuery,
                                      isSomeItemsHidden: !dependency.userSettingStorage.readShowHiddenItems(),
                                      previousState: state)

        return (nextState, [albumsEffect, settingsEffect])
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
        performFilter(albums: previousState.albums.orderedEntities(),
                      searchQuery: searchQuery,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        performFilter(albums: previousState.albums.orderedEntities(),
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
        var searchStorage = previousState.searchStorage

        let filteringAlbums = albums.filter { isSomeItemsHidden ? $0.isHidden == false : true }
        let filteredAlbumIds = searchStorage.perform(query: searchQuery, to: filteringAlbums).map { $0.id }
        let newAlbums = previousState.albums
            .updated(entities: albums)
            .updated(filteredIds: Set(filteredAlbumIds))
        nextState.albums = newAlbums

        nextState.searchQuery = searchQuery
        nextState.isSomeItemsHidden = isSomeItemsHidden
        nextState.isCollectionViewHidden = filteringAlbums.isEmpty
        nextState.isEmptyMessageViewHidden = !filteringAlbums.isEmpty
        nextState.searchStorage = searchStorage

        nextState.quickAddButtonTitle = L10n.quickAddAlbum(searchQuery)
        nextState.isQuickAddButtonHidden = !filteredAlbumIds.isEmpty

        if filteringAlbums.isEmpty, !searchQuery.isEmpty {
            nextState.searchQuery = ""
        }

        return nextState
    }
}
