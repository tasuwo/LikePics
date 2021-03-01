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

        case let .editingChanged(isEditing: isEditing):
            let newState = state
                .updating(isEditing: isEditing)
                .updating(isDragInteractionEnabled: isEditing)
                .updating(isAddButtonEnabled: !isEditing)
            return (newState, .none)

        // MARK: CollectionView

        case let .selected(albumId):
            guard !state.isEditing else { return (state, .none) }
            dependency.router.showClipCollectionView(for: albumId)
            return (state, .none)

        // MARK: NavigationBar

        case .addButtonTapped:
            return (state.updating(alert: .addition), .none)

        // MARK: Button Action

        case let .removerTapped(albumId, indexPath):
            guard let title = state._albums[albumId]?.value.title else { return (state, .none) }
            return (state.updating(alert: .deletion(albumId: albumId, title: title, at: indexPath)), .none)

        case let .editingTitleTapped(albumId):
            guard let title = state._albums[albumId]?.value.title else { return (state, .none) }
            return (state.updating(alert: .renaming(albumId: albumId, title: title)), .none)

        case .emptyMessageViewActionButtonTapped:
            return (state.updating(alert: .addition), .none)

        // MARK: Reorder

        case let .reordered(albumIds):
            let originals = state._orderedAlbums.map { $0.id }
            let newOrder = performReorder(originals: originals, request: albumIds)
            switch dependency.clipCommandService.updateAlbums(byReordering: newOrder) {
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtReorder)), .none)
            }

        // MARK: Context Menu

        case let .renameMenuTapped(albumId):
            guard let title = state._albums[albumId]?.value.title else { return (state, .none) }
            return (state.updating(alert: .renaming(albumId: albumId, title: title)), .none)

        case let .hideMenuTapped(albumId):
            if state.isSomeItemsHidden {
                let stream = Deferred {
                    Future<Action?, Never> { promise in
                        // HACK: アイテム削除とContextMenuのドロップのアニメーションがコンフリクトするため、
                        //       アイテム削除を遅延させて自然なアニメーションにする
                        //       https://stackoverflow.com/a/57997005
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
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
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.albumListViewErrorAtRevealAlbum)), .none)
            }

        case let .deleteMenuTapped(albumId, indexPath):
            guard let title = state._albums[albumId]?.value.title else { return (state, .none) }
            return (state.updating(alert: .deletion(albumId: albumId, title: title, at: indexPath)), .none)

        case let .deferredHide(albumId):
            switch dependency.clipCommandService.updateAlbum(having: albumId, byHiding: true) {
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.albumListViewErrorAtHideAlbum)), .none)
            }

        // MARK: Alert Completion

        case let .alertSaveButtonTapped(text: text):
            switch state.alert {
            case .addition:
                switch dependency.clipCommandService.create(albumWithTitle: text) {
                case .success:
                    return (state.updating(alert: nil), .none)

                case .failure:
                    return (state.updating(alert: .error(L10n.albumListViewErrorAtAddAlbum)), .none)
                }

            case let .renaming(albumId: albumId, title: _):
                switch dependency.clipCommandService.updateAlbum(having: albumId, titleTo: text) {
                case .success:
                    return (state.updating(alert: nil), .none)

                case .failure:
                    return (state.updating(alert: .error(L10n.albumListViewErrorAtEditAlbum)), .none)
                }

            default:
                return (state.updating(alert: nil), .none)
            }

        case .alertDeleteConfirmed:
            guard case let .deletion(albumId: albumId, title: _, at: _) = state.alert else { return (state.updating(alert: nil), .none) }
            switch dependency.clipCommandService.deleteAlbum(having: albumId) {
            case .success:
                return (state.updating(alert: nil), .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtDeleteClips)), .none)
            }

        case .alertDismissed:
            return (state.updating(alert: nil), .none)
        }
    }
}

// MARK: - Preparation

extension AlbumListViewReducer {
    static func prepareQueryEffects(_ dependency: Dependency) -> [Effect<Action>] {
        let query: AlbumListQuery
        switch dependency.clipQueryService.queryAllAlbums() {
        case let .success(result):
            query = result

        case let .failure(error):
            fatalError("Failed to load albums: \(error.localizedDescription)")
        }

        let albumsStream = query.albums
            .catch { _ in
                // TODO: Error state
                Just([])
            }
            .map { Action.albumsUpdated($0) as Action? }
        let albumsEffect = Effect(albumsStream, underlying: query)

        let settingsStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.settingUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingsEffect = Effect(settingsStream)

        return [albumsEffect, settingsEffect]
    }
}

// MARK: - Filter

extension AlbumListViewReducer {
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

private extension AlbumListViewState {
    var shouldClearQuery: Bool { _albums.isEmpty && !searchQuery.isEmpty }
}
