//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias ClipCollectionDependency = HasRouter
    & HasUserSettingStorage
    & HasClipCommandService
    & HasClipQueryService

enum ClipCollectionReducer: Reducer {
    typealias Dependency = ClipCollectionDependency
    typealias State = ClipCollectionState
    typealias Action = ClipCollectionAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        switch action {
        case .viewDidLoad:
            return (state, prepareQueryEffects(dependency))

        case let .clipsUpdated(clips):
            return (performFilter(clips: clips, previousState: state), .none)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return (performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state), .none)

        case let .selected(clipId):
            var nextState: State

            let selections: Set<Clip.Identity> = {
                if state.operation.isAllowedMultipleSelection {
                    return state.selections.union(Set([clipId]))
                } else {
                    return Set([clipId])
                }
            }()
            nextState = state.updating(selections: selections)

            if !state.operation.isAllowedMultipleSelection {
                dependency.router.showClipPreviewView(for: clipId)
                // TODO:
                nextState = state.updating(_previewingClipId: clipId)
            }

            return (nextState, .none)

        case let .deselected(clipId):
            guard state.selections.contains(clipId) else { return (state, .none) }
            return (state.updating(selections: state.selections.subtracting(Set([clipId]))), .none)

        // MARK: NavigationBar/ToolBar

        case let .navigationBarEventOccurred(event):
            return handle(event, state: state, dependency: dependency)

        case let .toolBarEventOccurred(event):
            return handle(event, state: state, dependency: dependency)

        // MARK: Actions for Single Clip

        case let .tagAdditionMenuTapped(clipId):
            switch dependency.clipQueryService.readClipAndTags(for: [clipId]) {
            case let .success((_, tags)):
                let effect = showTagSelectionModal(for: .init([clipId]), selections: Set(tags.map({ $0.id })), dependency: dependency)
                return (state, [effect])

            case .failure:
                return (state.updating(alert: .error(L10n.errorTagRead)), .none)
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
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
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtHideClip)), .none)
            }

        case let .revealMenuTapped(clipId):
            switch dependency.clipCommandService.updateClips(having: [clipId], byHiding: false) {
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtHideClip)), .none)
            }

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

        case let .shareMenuTapped(clipId, _):
            let effect = showShareModal(from: .menu(clipId), for: Set([clipId]), dependency: dependency)
            return (state, [effect])

        case let .purgeMenuTapped(clipId, indexPath):
            return (state.updating(alert: .purge(clipId: clipId, at: indexPath)), .none)

        case let .deleteMenuTapped(clipId, indexPath):
            return (state.updating(alert: .deletion(clipId: clipId, at: indexPath)), .none)

        case let .removeFromAlbumMenuTapped(clipId, _):
            guard let albumId = state.context.albumId else { return (state, .none) }
            switch dependency.clipCommandService.updateAlbum(having: albumId, byDeletingClipsHaving: [clipId]) {
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtRemoveClipsFromAlbum)), .none)
            }

        // MARK: Modal Completion

        case let .tagsSelected(tagIds, for: clipIds):
            guard let tagIds = tagIds else { return (state, .none) }
            switch dependency.clipCommandService.updateClips(having: Array(clipIds), byReplacingTagsHaving: Array(tagIds)) {
            case .success:
                return (state.endEditing(), .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtUpdateTagsToClip)), .none)
            }

        case let .albumsSelected(albumId, for: clipIds):
            guard let albumId = albumId else { return (state, .none) }
            switch dependency.clipCommandService.updateAlbum(having: albumId, byAddingClipsHaving: Array(clipIds)) {
            case .success:
                return (state.endEditing(), .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtAddClipToAlbum)), .none)
            }

        case let .modalCompleted(succeeded):
            if succeeded {
                return (state.endEditing(), .none)
            } else {
                return (state, .none)
            }

        // MARK: Alert Completion

        case .alertDeleteConfirmed:
            guard case let .deletion(clipId: clipId, at: _) = state.alert else { return (state.updating(alert: nil), .none) }
            switch dependency.clipCommandService.deleteClips(having: [clipId]) {
            case .success:
                return (state.updating(alert: nil).endEditing(), .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtDeleteClips)), .none)
            }

        case .alertPurgeConfirmed:
            guard case let .purge(clipId: clipId, at: _) = state.alert else { return (state.updating(alert: nil), .none) }
            switch dependency.clipCommandService.purgeClipItems(forClipHaving: clipId) {
            case .success:
                return (state.updating(alert: nil), .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtPurge)), .none)
            }

        case .alertDismissed:
            return (state.updating(alert: nil), .none)
        }
    }
}

// MARK: - Preparation

extension ClipCollectionReducer {
    static func prepareQueryEffects(_ dependency: Dependency) -> [Effect<Action>] {
        let query: ClipListQuery
        switch dependency.clipQueryService.queryAllClips() {
        case let .success(result):
            query = result

        case let .failure(error):
            fatalError("Failed to load tags: \(error.localizedDescription)")
        }

        let clipsStream = query.clips
            .catch { _ in Just([]) }
            .map { Action.clipsUpdated($0) as Action? }
        let tagsEffect = Effect(clipsStream, underlying: query)

        let settingsStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.settingUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingsEffect = Effect(settingsStream)

        return [tagsEffect, settingsEffect]
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

    static func showShareModal(from source: ClipCollection.ShareSource, for clipIds: Set<Clip.Identity>, dependency: HasRouter) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                let isPresented = dependency.router.showShareModal(from: source, clips: clipIds) { succeeded in
                    promise(.success(.modalCompleted(succeeded)))
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
        performFilter(clips: clips, isSomeItemsHidden: previousState.isSomeItemsHidden, previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        performFilter(clips: previousState._orderedClips, isSomeItemsHidden: isSomeItemsHidden, previousState: previousState)
    }

    private static func performFilter(clips: [Clip],
                                      isSomeItemsHidden: Bool,
                                      previousState: State) -> State
    {
        var newState = previousState

        let dict = clips.enumerated().reduce(into: [Clip.Identity: State.OrderedClip]()) { dict, value in
            dict[value.element.id] = State.OrderedClip(index: value.offset, value: value.element)
        }

        let filteredClipIds = clips
            .filter { clip in
                if isSomeItemsHidden { return !clip.isHidden }
                return true
            }
            .map { $0.id }

        newState = newState
            .updating(_clips: dict)
            .updating(_filteredClipIds: Set(filteredClipIds))
            .updating(isEmptyMessageViewDisplaying: filteredClipIds.isEmpty, isCollectionViewDisplaying: !filteredClipIds.isEmpty)
            .updating(isSomeItemsHidden: isSomeItemsHidden)

        // 余分な選択を除外する
        let newClipIds = Set(clips.map { $0.id })
        if !previousState.selections.isSubset(of: newClipIds) {
            let newSelections = previousState.selections.subtracting(
                previousState.selections.subtracting(newClipIds)
            )
            newState = newState.updating(selections: newSelections)
        }

        return newState
    }
}

// MARK: NavigationBar Event

extension ClipCollectionReducer {
    private static func handle(_ event: ClipCollectionNavigationBarEvent,
                               state: State,
                               dependency: Dependency) -> (State, [Effect<Action>]?)
    {
        switch event {
        case .cancel:
            let newState = state
                .updating(operation: .none)
                .updating(selections: [])
            return (newState, .none)

        case .selectAll:
            guard state.operation.isAllowedMultipleSelection else { return (state, .none) }
            return (state.updating(selections: Set(state._clips.keys)), .none)

        case .deselectAll:
            return (state.updating(selections: []), .none)

        case .select:
            let newState = state
                .updating(operation: .selecting)
                .updating(selections: [])
            return (newState, .none)

        case .reorder:
            let newState = state
                .updating(operation: .reordering)
                .updating(selections: [])
            return (newState, .none)

        case .done:
            let newState = state
                .updating(operation: .none)
                .updating(selections: [])
            return (newState, .none)
        }
    }
}

// MARK: ToolBar Event

extension ClipCollectionReducer {
    private static func handle(_ event: ClipCollectionToolBarEvent,
                               state: State,
                               dependency: Dependency) -> (State, [Effect<Action>]?)
    {
        switch event {
        case .addToAlbum:
            let effect = showAlbumSelectionModal(for: state.selections, dependency: dependency)
            return (state.updating(alert: nil), [effect])

        case .addTags:
            let effect = showTagSelectionModal(for: state.selections, selections: .init(), dependency: dependency)
            return (state.updating(alert: nil), [effect])

        case .hide:
            switch dependency.clipCommandService.updateClips(having: Array(state.selections), byHiding: true) {
            case .success:
                return (state.endEditing(), .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtHideClips)), .none)
            }

        case .reveal:
            switch dependency.clipCommandService.updateClips(having: Array(state.selections), byHiding: false) {
            case .success:
                return (state.endEditing(), .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtRevealClips)), .none)
            }

        case .share:
            let effect = showShareModal(from: .toolBar, for: state.selections, dependency: dependency)
            return (state, [effect])

        case .delete:
            switch dependency.clipCommandService.deleteClips(having: Array(state.selections)) {
            case .success:
                return (state.updating(alert: nil).endEditing(), .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtDeleteClips)), .none)
            }

        case .removeFromAlbum:
            guard let albumId = state.context.albumId else { return (state, .none) }
            switch dependency.clipCommandService.updateAlbum(having: albumId, byDeletingClipsHaving: Array(state.selections)) {
            case .success:
                return (state, .none)

            case .failure:
                return (state.updating(alert: .error(L10n.clipCollectionErrorAtRemoveClipsFromAlbum)), .none)
            }

        case .merge:
            let selections = state.selectedClips
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

private extension ClipCollectionState {
    func endEditing() -> Self {
        return .init(selections: .init(),
                     isSomeItemsHidden: isSomeItemsHidden,
                     operation: .none,
                     isEmptyMessageViewDisplaying: isEmptyMessageViewDisplaying,
                     isCollectionViewDisplaying: isCollectionViewDisplaying,
                     alert: alert,
                     context: context,
                     _clips: _clips,
                     _filteredClipIds: _filteredClipIds,
                     _previewingClipId: _previewingClipId)
    }
}
