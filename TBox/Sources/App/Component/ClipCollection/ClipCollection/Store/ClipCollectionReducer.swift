//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit

typealias ClipCollectionDependency = HasRouter
    & HasUserSettingStorage
    & HasClipCommandService
    & HasClipQueryService
    & HasImageQueryService

struct ClipCollectionReducer: Reducer {
    typealias Dependency = ClipCollectionDependency
    typealias State = ClipCollectionState
    typealias Action = ClipCollectionAction

    // swiftlint:disable:next function_body_length
    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        switch action {
        // MARK: View Life-Cycle

        case .viewWillLayoutSubviews:
            guard !nextState.isPreparedQueryEffects else { return (nextState, .none) }
            nextState.isPreparedQueryEffects = true
            return Self.prepare(state: nextState, dependency: dependency)

        // MARK: State Observation

        case let .clipsUpdated(clips):
            return (Self.performFilter(clips: clips, previousState: state), .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (Self.performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state), .none)

        // MARK: Selection

        case let .selected(clipId):
            let selections: Set<Clip.Identity> = {
                if state.operation.isAllowedMultipleSelection {
                    return state.clips._selectedIds.union(Set([clipId]))
                } else {
                    return Set([clipId])
                }
            }()
            nextState.clips = state.clips.updated(selectedIds: selections)

            if !state.operation.isAllowedMultipleSelection {
                dependency.router.showClipPreviewView(for: clipId)
            }

            return (nextState, .none)

        case let .deselected(clipId):
            guard state.clips._selectedIds.contains(clipId) else { return (state, .none) }
            let newSelections = state.clips._selectedIds.subtracting(Set([clipId]))
            nextState.clips = nextState.clips.updated(selectedIds: newSelections)
            return (nextState, .none)

        case let .reordered(clipIds):
            guard case let .album(albumId) = state.source else { return (state, .none) }

            let originals = state.clips.orderedEntities().map { $0.id }
            guard Set(originals).count == originals.count, Set(clipIds).count == clipIds.count else {
                nextState.alert = .error(L10n.albumListViewErrorAtReorderAlbum)
                return (nextState, .none)
            }

            let ids = Self.performReorder(originals: originals, request: clipIds)
            switch dependency.clipCommandService.updateAlbum(having: albumId, byReorderingClipsHaving: ids) {
            case .success:
                let newClips = ids
                    .compactMap { state.clips.entity(having: $0) }
                    .indexed()
                nextState.clips = nextState.clips.updated(entities: newClips)

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtReorder)
            }
            return (nextState, .none)

        // MARK: NavigationBar/ToolBar

        case let .navigationBarEventOccurred(event):
            return Self.execute(action: event, state: state, dependency: dependency)

        case let .toolBarEventOccurred(event):
            return Self.execute(action: event, state: state, dependency: dependency)

        // MARK: Actions for Single Clip

        case let .tagAdditionMenuTapped(clipId):
            switch dependency.clipQueryService.readClipAndTags(for: [clipId]) {
            case let .success((_, tags)):
                nextState.modal = .tagSelection(id: UUID(), clipIds: .init([clipId]), tagIds: Set(tags.map({ $0.id })))
                return (nextState, .none)

            case .failure:
                nextState.alert = .error(L10n.errorTagRead)
                return (nextState, .none)
            }

        case let .albumAdditionMenuTapped(clipId):
            nextState.modal = .albumSelection(id: UUID(), clipIds: .init([clipId]))
            return (nextState, .none)

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
            nextState.modal = .clipEdit(id: UUID(), clipId: clipId)
            return (nextState, .none)

        case let .shareMenuTapped(clipId):
            guard let imageIds = state.clips.entity(having: clipId)?.items.map({ $0.imageId }) else { return (state, .none) }
            nextState.alert = .share(clipId: clipId, imageIds: imageIds)
            return (nextState, .none)

        case let .purgeMenuTapped(clipId):
            nextState.alert = .purge(clipId: clipId)
            return (nextState, .none)

        case let .deleteMenuTapped(clipId):
            nextState.alert = .deletion(clipId: clipId)
            return (nextState, .none)

        case let .removeFromAlbumMenuTapped(clipId):
            nextState.alert = .removeFromAlbum(clipId: clipId)
            return (nextState, .none)

        // MARK: Modal Completion

        case let .tagsSelected(tagIds):
            guard case let .tagSelection(id: _, clipIds: clipIds, tagIds: _) = nextState.modal,
                  let tagIds = tagIds
            else {
                nextState.modal = nil
                return (nextState, .none)
            }

            nextState.modal = nil

            switch dependency.clipCommandService.updateClips(having: Array(clipIds), byReplacingTagsHaving: Array(tagIds)) {
            case .success:
                nextState = nextState.editingEnded()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtUpdateTagsToClip)
            }
            return (nextState, .none)

        case let .albumSelected(albumId):
            guard case let .albumSelection(id: _, clipIds: clipIds) = nextState.modal,
                  let albumId = albumId
            else {
                nextState.modal = nil
                return (nextState, .none)
            }

            nextState.modal = nil

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
            nextState.modal = nil
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

        case .alertRemoveFromAlbumConfirmed:
            guard case let .removeFromAlbum(clipId: clipId) = state.alert,
                  case let .album(albumId) = state.source
            else {
                nextState.alert = nil
                return (nextState, .none)
            }
            switch dependency.clipCommandService.updateAlbum(having: albumId, byDeletingClipsHaving: [clipId]) {
            case .success:
                nextState.alert = nil

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtRemoveClipsFromAlbum)
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
        performFilter(clips: previousState.clips.orderedEntities(),
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
            .updated(entities: clips.indexed())
            .updated(filteredIds: Set(filteredClipIds))

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
            nextState.layout = state.preservedLayout ?? state.layout
            nextState.preservedLayout = nil
            nextState.clips = nextState.clips.updated(selectedIds: .init())
            return (nextState, .none)

        case .selectAll:
            guard state.operation.isAllowedMultipleSelection else { return (state, .none) }
            nextState.clips = nextState.clips.updated(selectedIds: state.clips._filteredIds)
            return (nextState, .none)

        case .deselectAll:
            nextState.clips = nextState.clips.updated(selectedIds: .init())
            return (nextState, .none)

        case .select:
            nextState.operation = .selecting
            nextState.layout = .grid
            nextState.preservedLayout = state.layout
            nextState.clips = nextState.clips.updated(selectedIds: .init())
            return (nextState, .none)

        case .changeLayout:
            nextState.layout = nextState.layout.nextLayout
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
            nextState.modal = .albumSelection(id: UUID(), clipIds: nextState.clips.selectedIds())
            nextState.alert = nil
            return (nextState, .none)

        case .addTags:
            nextState.modal = .tagSelection(id: UUID(), clipIds: nextState.clips.selectedIds(), tagIds: .init())
            nextState.alert = nil
            return (nextState, .none)

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
            let selections = state.clips.orderedSelectedEntities()
            nextState.modal = .clipMerge(id: UUID(), clips: selections)
            return (nextState, .none)
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
        nextState.clips = nextState.clips.updated(selectedIds: .init())
        nextState.operation = .none
        nextState.layout = preservedLayout ?? layout
        nextState.preservedLayout = nil
        return nextState
    }
}
