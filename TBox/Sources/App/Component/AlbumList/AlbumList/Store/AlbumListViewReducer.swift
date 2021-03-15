//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias AlbumListViewDependency = HasUserSettingStorage
    & HasClipCommandService
    & HasClipQueryService
    & HasRouter

enum AlbumListViewReducer: Reducer {
    typealias Dependency = AlbumListViewDependency
    typealias State = AlbumListViewState
    typealias Action = AlbumListViewAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return prepareQueryEffects(state, dependency)

        // MARK: State Observation

        case let .albumsUpdated(albums):
            return (performFilter(albums: albums, previousState: state), .none)

        case let .searchQueryChanged(query):
            return (performFilter(searchQuery: query, previousState: state), .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state), .none)

        case let .editingChanged(isEditing: isEditing):
            nextState.isEditing = isEditing
            nextState.isDragInteractionEnabled = isEditing
            nextState.isAddButtonEnabled = !isEditing
            return (nextState, .none)

        // MARK: CollectionView

        case let .selected(albumId):
            guard !state.isEditing else { return (state, .none) }
            dependency.router.showClipCollectionView(for: albumId)
            return (state, .none)

        // MARK: NavigationBar

        case .addButtonTapped:
            nextState.alert = .addition
            return (nextState, .none)

        // MARK: Button Action

        case let .removerTapped(albumId):
            guard let title = state.albums._values[albumId]?.value.title else { return (state, .none) }
            nextState.alert = .deletion(albumId: albumId, title: title)
            return (nextState, .none)

        case let .editingTitleTapped(albumId):
            guard let title = state.albums._values[albumId]?.value.title else { return (state, .none) }
            nextState.alert = .renaming(albumId: albumId, title: title)
            return (nextState, .none)

        case .emptyMessageViewActionButtonTapped:
            nextState.alert = .addition
            return (nextState, .none)

        // MARK: Reorder

        case let .reordered(albumIds):
            let originals = state.albums.orderedValues.map { $0.id }
            let newOrder = performReorder(originals: originals, request: albumIds)
            switch dependency.clipCommandService.updateAlbums(byReordering: newOrder) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtReorder)
            }
            return (nextState, .none)

        // MARK: Context Menu

        case let .renameMenuTapped(albumId):
            guard let title = state.albums._values[albumId]?.value.title else { return (state, .none) }
            nextState.alert = .renaming(albumId: albumId, title: title)
            return (nextState, .none)

        case let .hideMenuTapped(albumId):
            if state._isSomeItemsHidden {
                let stream = Deferred {
                    Future<Action?, Never> { promise in
                        // HACK: アイテム削除とContextMenuのドロップのアニメーションがコンフリクトするため、
                        //       アイテム削除を遅延させて自然なアニメーションにする
                        //       https://stackoverflow.com/a/57997005
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            promise(.success(.deferredHide(albumId)))
                        }
                    }
                }
                return (state, [Effect(stream)])
            } else {
                return (state, [Effect(value: .deferredHide(albumId))])
            }

        case let .revealMenuTapped(albumId):
            switch dependency.clipCommandService.updateAlbum(having: albumId, byHiding: false) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.albumListViewErrorAtRevealAlbum)
            }
            return (nextState, .none)

        case let .deleteMenuTapped(albumId):
            guard let title = state.albums._values[albumId]?.value.title else { return (state, .none) }
            nextState.alert = .deletion(albumId: albumId, title: title)
            return (nextState, .none)

        case let .deferredHide(albumId):
            switch dependency.clipCommandService.updateAlbum(having: albumId, byHiding: true) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.albumListViewErrorAtHideAlbum)
            }
            return (nextState, .none)

        // MARK: Alert Completion

        case let .alertSaveButtonTapped(text: text):
            switch state.alert {
            case .addition:
                switch dependency.clipCommandService.create(albumWithTitle: text) {
                case .success:
                    nextState.alert = nil

                case .failure:
                    nextState.alert = .error(L10n.albumListViewErrorAtAddAlbum)
                }

            case let .renaming(albumId: albumId, title: _):
                switch dependency.clipCommandService.updateAlbum(having: albumId, titleTo: text) {
                case .success:
                    nextState.alert = nil

                case .failure:
                    nextState.alert = .error(L10n.albumListViewErrorAtEditAlbum)
                }

            default:
                nextState.alert = nil
            }
            return (nextState, .none)

        case .alertDeleteConfirmed:
            guard case let .deletion(albumId: albumId, title: _) = state.alert else {
                nextState.alert = nil
                return (nextState, .none)
            }
            switch dependency.clipCommandService.deleteAlbum(having: albumId) {
            case .success:
                nextState.alert = nil

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtDeleteClips)
            }
            return (nextState, .none)

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension AlbumListViewReducer {
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

extension AlbumListViewReducer {
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
            .updated(_values: albums.map({ isSomeItemsHidden ? $0.removingHiddenClips() : $0 }).indexed())
            .updated(_displayableIds: Set(filteredAlbumIds))
        nextState.albums = newAlbums

        nextState.searchQuery = searchQuery
        nextState._isSomeItemsHidden = isSomeItemsHidden
        nextState.isCollectionViewDisplaying = !filteringAlbums.isEmpty
        nextState.isEmptyMessageViewDisplaying = filteringAlbums.isEmpty
        nextState.isSearchBarEnabled = !filteringAlbums.isEmpty
        nextState._searchStorage = searchStorage

        if filteringAlbums.isEmpty, !searchQuery.isEmpty {
            nextState.searchQuery = ""
        }

        return nextState
    }
}

// MARK: - Reorder

extension AlbumListViewReducer {
    static func performReorder(originals: [Album.Identity], request: [Album.Identity]) -> [Album.Identity] {
        var index = 0
        return originals
            .map { original in
                guard request.contains(original) else { return original }
                index += 1
                return request[index - 1]
            }
    }
}
