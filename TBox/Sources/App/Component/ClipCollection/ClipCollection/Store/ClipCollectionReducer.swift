//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias ClipCollectionDependency = HasRouter
    & HasUserSettingStorage
    & HasClipCommandService
    & HasClipQueryService
    & HasImageQueryService

enum ClipCollectionReducer: Reducer {
    typealias Dependency = ClipCollectionDependency
    typealias State = ClipCollectionState
    typealias Action = ClipCollectionAction

    // swiftlint:disable:next function_body_length
    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return prepare(state: state, dependency: dependency)

        case .viewDidAppear:
            nextState.previewingClipId = nil
            return (nextState, .none)

        // MARK: State Observation

        case let .clipsUpdated(clips):
            return (performFilter(clips: clips, previousState: state), .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state), .none)

        // MARK: Selection

        case let .selected(clipId):
            let selections: Set<Clip.Identity> = {
                if state.operation.isAllowedMultipleSelection {
                    return state.clips._selectedIds.union(Set([clipId]))
                } else {
                    return Set([clipId])
                }
            }()
            nextState.clips = state.clips.updated(_selectedIds: selections)

            if !state.operation.isAllowedMultipleSelection {
                dependency.router.showClipPreviewView(for: clipId)
                nextState.previewingClipId = clipId
            }

            return (nextState, .none)

        case let .deselected(clipId):
            guard state.clips._selectedIds.contains(clipId) else { return (state, .none) }
            let newSelections = state.clips._selectedIds.subtracting(Set([clipId]))
            nextState.clips = nextState.clips.updated(_selectedIds: newSelections)
            return (nextState, .none)

        case let .reordered(clipIds):
            guard case let .album(albumId) = state.source else { return (state, .none) }

            let originals = state.clips.orderedValues.map { $0.id }
            guard Set(originals).count == originals.count, Set(clipIds).count == clipIds.count else {
                nextState.alert = .error(L10n.albumListViewErrorAtReorderAlbum)
                return (nextState, .none)
            }

            let ids = self.performReorder(originals: originals, request: clipIds)
            switch dependency.clipCommandService.updateAlbum(having: albumId, byReorderingClipsHaving: ids) {
            case .success:
                let newClips = ids
                    .compactMap { state.clips._values[$0]?.value }
                    .indexed()
                nextState.clips = nextState.clips.updated(_values: newClips)

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtReorder)
            }
            return (nextState, .none)

        // MARK: NavigationBar/ToolBar

        case let .navigationBarEventOccurred(event):
            return execute(action: event, state: state, dependency: dependency)

        case let .toolBarEventOccurred(event):
            return execute(action: event, state: state, dependency: dependency)

        // MARK: Actions for Single Clip

        case let .tagAdditionMenuTapped(clipId):
            switch dependency.clipQueryService.readClipAndTags(for: [clipId]) {
            case let .success((_, tags)):
                let effect = showTagSelectionModal(for: .init([clipId]), selections: Set(tags.map({ $0.id })), dependency: dependency)
                return (state, [effect])

            case .failure:
                nextState.alert = .error(L10n.errorTagRead)
                return (nextState, .none)
            }

        case let .albumAdditionMenuTapped(clipId):
            let effect = showAlbumSelectionModal(for: Set([clipId]), dependency: dependency)
            return (state, [effect])

        case let .hideMenuTapped(clipId):
            if state.isSomeItemsHidden {
                let stream = Deferred {
                    Future<Action?, Never> { promise in
                        // HACK: アイテム削除とContextMenuのドロップのアニメーションがコンフリクトするため、
                        //       アイテム削除を遅延させて自然なアニメーションにする
                        //       https://stackoverflow.com/a/57997005
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            promise(.success(.deferredHide(clipId)))
                        }
                    }
                }
                return (state, [Effect(stream)])
            } else {
                return (state, [Effect(value: .deferredHide(clipId))])
            }

        case let .deferredHide(clipId):
            switch dependency.clipCommandService.updateClips(having: [clipId], byHiding: true) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtHideClip)
            }
            return (nextState, .none)

        case let .revealMenuTapped(clipId):
            switch dependency.clipCommandService.updateClips(having: [clipId], byHiding: false) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtHideClip)
            }
            return (nextState, .none)

        case let .editMenuTapped(clipId):
            let stream = Deferred {
                Future<Action?, Never> { promise in
                    let isPresented = dependency.router.showClipEditModal(for: clipId) { succeeded in
                        promise(.success(.modalCompleted(succeeded)))
                    }
                    if !isPresented {
                        promise(.success(.modalCompleted(false)))
                    }
                }
            }
            return (state, [Effect(stream)])

        case let .shareMenuTapped(clipId):
            guard let imageIds = state.clips._values[clipId]?.value.items.map({ $0.imageId }) else { return (state, .none) }
            let items = imageIds.compactMap { imageId in
                ClipItemImageShareItem(imageId: imageId, imageQueryService: dependency.imageQueryService)
            }
            nextState.alert = .share(clipId: clipId, items: items)
            return (nextState, .none)

        case let .purgeMenuTapped(clipId):
            nextState.alert = .purge(clipId: clipId)
            return (nextState, .none)

        case let .deleteMenuTapped(clipId):
            nextState.alert = .deletion(clipId: clipId)
            return (nextState, .none)

        case let .removeFromAlbumMenuTapped(clipId):
            guard case let .album(albumId) = state.source else { return (state, .none) }
            switch dependency.clipCommandService.updateAlbum(having: albumId, byDeletingClipsHaving: [clipId]) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtRemoveClipsFromAlbum)
            }
            return (nextState, .none)

        // MARK: Modal Completion

        case let .tagsSelected(tagIds, for: clipIds):
            guard let tagIds = tagIds else { return (state, .none) }
            switch dependency.clipCommandService.updateClips(having: Array(clipIds), byReplacingTagsHaving: Array(tagIds)) {
            case .success:
                nextState = nextState.editingEnded()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtUpdateTagsToClip)
            }
            return (nextState, .none)

        case let .albumsSelected(albumId, for: clipIds):
            guard let albumId = albumId else { return (state, .none) }
            switch dependency.clipCommandService.updateAlbum(having: albumId, byAddingClipsHaving: Array(clipIds)) {
            case .success:
                nextState = nextState.editingEnded()

            case .failure(.duplicated):
                nextState.alert = .error(L10n.clipCollectionErrorAtAddClipsToAlbumDuplicated)

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtAddClipToAlbum)
            }
            return (nextState, .none)

        case let .modalCompleted(succeeded):
            if succeeded { nextState = nextState.editingEnded() }
            return (nextState, .none)

        // MARK: Alert Completion

        case .alertDeleteConfirmed:
            guard case let .deletion(clipId: clipId) = state.alert else {
                nextState.alert = nil
                return (nextState, .none)
            }
            switch dependency.clipCommandService.deleteClips(having: [clipId]) {
            case .success:
                nextState.alert = nil
                nextState = nextState.editingEnded()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtDeleteClips)
            }
            return (nextState, .none)

        case .alertPurgeConfirmed:
            guard case let .purge(clipId: clipId) = state.alert else {
                nextState.alert = nil
                return (nextState, .none)
            }
            switch dependency.clipCommandService.purgeClipItems(forClipHaving: clipId) {
            case .success:
                nextState.alert = nil

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtPurge)
            }
            return (nextState, .none)

        case let .alertShareDismissed(succeeded):
            if succeeded { nextState = nextState.editingEnded() }
            nextState.alert = nil
            return (nextState, .none)

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)

        // MARK: Transition

        case .failedToLoad, .albumDeleted:
            nextState.isDismissed = true
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension ClipCollectionReducer {
    static func prepare(state: State, dependency: Dependency) -> (State, [Effect<Action>]) {
        let queryEffect: Effect<Action>
        let description: String?

        let initialClips: [Clip]
        switch state.source {
        case .all:
            let query: ClipListQuery
            switch dependency.clipQueryService.queryAllClips() {
            case let .success(result):
                query = result

            case let .failure(error):
                fatalError("Failed to load clips: \(error.localizedDescription)")
            }
            let clipsStream = query.clips
                .map { Action.clipsUpdated($0) as Action? }
                .catch { _ in Just(Action.failedToLoad) }
            queryEffect = Effect(clipsStream, underlying: query, completeWith: .failedToLoad)
            description = L10n.clipCollectionViewTitleAll
            initialClips = query.clips.value

        case let .album(albumId):
            let query: AlbumQuery
            switch dependency.clipQueryService.queryAlbum(having: albumId) {
            case let .success(result):
                query = result

            case let .failure(error):
                fatalError("Failed to load clips: \(error.localizedDescription)")
            }
            let albumStream = query.album
                .flatMap { Just(Action.clipsUpdated($0.clips) as Action?) }
                .catch { _ in Just(Action.failedToLoad) }
            queryEffect = Effect(albumStream, underlying: query, completeWith: .albumDeleted)
            description = query.album.value.title
            initialClips = query.album.value.clips

        case .uncategorized:
            let query: ClipListQuery
            switch dependency.clipQueryService.queryUncategorizedClips() {
            case let .success(result):
                query = result

            case let .failure(error):
                fatalError("Failed to load clips: \(error.localizedDescription)")
            }
            let clipsStream = query.clips
                .map { Action.clipsUpdated($0) as Action? }
                .catch { _ in Just(Action.failedToLoad) }
            queryEffect = Effect(clipsStream, underlying: query, completeWith: .failedToLoad)
            description = L10n.searchResultTitleUncategorized
            initialClips = query.clips.value

        case let .tag(tag):
            let query: ClipListQuery
            switch dependency.clipQueryService.queryClips(tagged: tag.id) {
            case let .success(result):
                query = result

            case let .failure(error):
                fatalError("Failed to load clips: \(error.localizedDescription)")
            }
            let clipsStream = query.clips
                .map { Action.clipsUpdated($0) as Action? }
                .catch { _ in Just(Action.failedToLoad) }
            queryEffect = Effect(clipsStream, underlying: query, completeWith: .failedToLoad)
            description = tag.name
            initialClips = query.clips.value

        case let .search(searchQuery):
            let query: ClipListQuery

            switch dependency.clipQueryService.queryClips(query: searchQuery) {
            case let .success(result):
                query = result

            case let .failure(error):
                fatalError("Failed to load clips: \(error.localizedDescription)")
            }
            let clipsStream = query.clips
                .map { Action.clipsUpdated($0) as Action? }
                .catch { _ in Just(Action.failedToLoad) }
            queryEffect = Effect(clipsStream, underlying: query, completeWith: .failedToLoad)
            description = searchQuery.displayTitle
            initialClips = query.clips.value
        }

        let settingsStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.settingUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingsEffect = Effect(settingsStream)

        var nextState = performFilter(clips: initialClips,
                                      isSomeItemsHidden: !dependency.userSettingStorage.readShowHiddenItems(),
                                      previousState: state)
        nextState.sourceDescription = description

        return (nextState, [queryEffect, settingsEffect])
    }
}

// MARK: - Router

extension ClipCollectionReducer {
    static func showTagSelectionModal(for clipIds: Set<Clip.Identity>, selections: Set<Tag.Identity>, dependency: HasRouter) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                let isPresented = dependency.router.showTagSelectionModal(selections: selections) { tags in
                    let tagIds: Set<Tag.Identity>? = {
                        guard let tags = tags else { return nil }
                        return Set(tags.map({ $0.id }))
                    }()
                    promise(.success(.tagsSelected(tagIds, for: clipIds)))
                }
                if !isPresented {
                    promise(.success(.modalCompleted(false)))
                }
            }
        }
        return Effect(stream)
    }

    static func showAlbumSelectionModal(for clipIds: Set<Clip.Identity>, dependency: HasRouter) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                let isPresented = dependency.router.showAlbumSelectionModal { albumId in
                    promise(.success(.albumsSelected(albumId, for: clipIds)))
                }
                if !isPresented {
                    promise(.success(.modalCompleted(false)))
                }
            }
        }
        return Effect(stream)
    }
}

// MARK: - Filter

extension ClipCollectionReducer {
    private static func performFilter(clips: [Clip],
                                      previousState: State) -> State
    {
        performFilter(clips: clips,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        performFilter(clips: previousState.clips.orderedValues,
                      isSomeItemsHidden: isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(clips: [Clip],
                                      isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        var nextState = previousState

        let filteredClips = clips.filter { isSomeItemsHidden ? $0.isHidden == false : true }
        let filteredClipIds = filteredClips.map { $0.id }

        nextState.clips = previousState.clips
            .updated(_values: clips.indexed())
            .updated(_displayableIds: Set(filteredClipIds))

        // 余分な選択を除外する
        let newClipIds = Set(clips.map { $0.id })
        if !nextState.clips._selectedIds.isSubset(of: newClipIds) {
            let newSelections = nextState.clips._selectedIds.subtracting(
                nextState.clips._selectedIds.subtracting(newClipIds)
            )
            nextState.clips = nextState.clips.updated(_selectedIds: newSelections)
        }

        nextState.isEmptyMessageViewDisplaying = filteredClips.isEmpty
        nextState.isCollectionViewDisplaying = !filteredClips.isEmpty
        nextState.isSomeItemsHidden = isSomeItemsHidden

        if previousState.isSomeItemsHidden != isSomeItemsHidden {
            nextState = nextState.editingEnded()
        }

        return nextState
    }
}

// MARK: NavigationBar Event

extension ClipCollectionReducer {
    private static func execute(action: ClipCollectionNavigationBarEvent,
                                state: State,
                                dependency: Dependency) -> (State, [Effect<Action>]?)
    {
        var nextState = state

        switch action {
        case .cancel:
            nextState.operation = .none
            nextState.clips = nextState.clips.updated(_selectedIds: .init())
            return (nextState, .none)

        case .selectAll:
            guard state.operation.isAllowedMultipleSelection else { return (state, .none) }
            nextState.clips = nextState.clips.updated(_selectedIds: state.clips._displayableIds)
            return (nextState, .none)

        case .deselectAll:
            nextState.clips = nextState.clips.updated(_selectedIds: .init())
            return (nextState, .none)

        case .select:
            nextState.operation = .selecting
            nextState.clips = nextState.clips.updated(_selectedIds: .init())
            return (nextState, .none)
        }
    }
}

// MARK: ToolBar Event

extension ClipCollectionReducer {
    private static func execute(action: ClipCollectionToolBarEvent,
                                state: State,
                                dependency: Dependency) -> (State, [Effect<Action>]?)
    {
        var nextState = state
        switch action {
        case .addToAlbum:
            let effect = showAlbumSelectionModal(for: state.clips._selectedIds, dependency: dependency)
            nextState.alert = nil
            return (nextState, [effect])

        case .addTags:
            let effect = showTagSelectionModal(for: state.clips._selectedIds, selections: .init(), dependency: dependency)
            nextState.alert = nil
            return (nextState, [effect])

        case .hide:
            switch dependency.clipCommandService.updateClips(having: Array(state.clips._selectedIds), byHiding: true) {
            case .success:
                nextState = nextState.editingEnded()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtHideClips)
            }
            return (nextState, .none)

        case .reveal:
            switch dependency.clipCommandService.updateClips(having: Array(state.clips._selectedIds), byHiding: false) {
            case .success:
                nextState = nextState.editingEnded()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtRevealClips)
            }
            return (nextState, .none)

        case let .share(succeeded):
            if succeeded { nextState = nextState.editingEnded() }
            nextState.alert = nil
            return (nextState, .none)

        case .delete:
            switch dependency.clipCommandService.deleteClips(having: Array(state.clips._selectedIds)) {
            case .success:
                nextState = nextState.editingEnded()
                nextState.alert = nil

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtDeleteClips)
            }
            return (nextState, .none)

        case .removeFromAlbum:
            guard case let .album(albumId) = state.source else { return (state, .none) }
            switch dependency.clipCommandService.updateAlbum(having: albumId, byDeletingClipsHaving: Array(state.clips._selectedIds)) {
            case .success:
                nextState = nextState.editingEnded()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtRemoveClipsFromAlbum)
            }
            return (nextState, .none)

        case .merge:
            let selections = state.clips.selectedValues
            let stream = Deferred {
                Future<Action?, Never> { promise in
                    let isPresented = dependency.router.showClipMergeModal(for: selections) { succeeded in
                        promise(.success(.modalCompleted(succeeded)))
                    }
                    if !isPresented {
                        promise(.success(.modalCompleted(false)))
                    }
                }
            }
            return (state, [Effect(stream)])
        }
    }
}

extension ClipCollectionReducer {
    private static func performReorder(originals: [Clip.Identity], request: [Clip.Identity]) -> [Clip.Identity] {
        var index = 0
        return originals
            .map { original in
                guard request.contains(original) else { return original }
                index += 1
                return request[index - 1]
            }
    }
}

private extension ClipCollectionState {
    func editingEnded() -> Self {
        var nextState = self
        nextState.clips = nextState.clips.updated(_selectedIds: .init())
        nextState.operation = .none
        return nextState
    }
}
