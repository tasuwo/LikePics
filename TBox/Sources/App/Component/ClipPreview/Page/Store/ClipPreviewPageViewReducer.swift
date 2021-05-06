//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias ClipPreviewPageViewDependency = HasRouter
    & HasClipCommandService
    & HasClipQueryService
    & HasClipInformationTransitioningController
    & HasClipInformationViewCaching
    & HasPreviewLoader
    & HasTransitionLock

enum ClipPreviewPageViewReducer: Reducer {
    typealias Dependency = ClipPreviewPageViewDependency
    typealias State = ClipPreviewPageViewState
    typealias Action = ClipPreviewPageViewAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return prepare(state: nextState, dependency: dependency)

        // MARK: State Observation

        case let .pageChanged(index: index):
            nextState.pageChange = nil
            nextState.currentIndex = index
            nextState.currentPreloadTargets().forEach {
                dependency.previewLoader.preloadPreview(imageId: $0)
            }
            return (nextState, .none)

        case let .clipUpdated(clip):
            defer {
                nextState.currentPreloadTargets().forEach {
                    dependency.previewLoader.preloadPreview(imageId: $0)
                }
            }

            guard !clip.items.isEmpty else {
                nextState.isDismissed = true
                return (nextState, .none)
            }

            nextState.items = clip.items.sorted(by: { $0.clipIndex < $1.clipIndex })

            guard let previousItemId = state.currentItem?.id else {
                nextState.currentIndex = 0
                return (nextState, .none)
            }

            if let newIndex = nextState.items.firstIndex(where: { $0.id == previousItemId }) {
                nextState.currentIndex = newIndex
                return (nextState, .none)
            } else {
                nextState.currentIndex = 0
                return (nextState, .none)
            }

        case .failedToLoadClip:
            nextState.isDismissed = true
            return (nextState, .none)

        // MARK: Transition

        case .clipInformationViewPresented:
            if let currentItemId = state.currentItem?.id,
               let cache = dependency.informationViewCache,
               let transitioningController = dependency.clipInformationTransitioningController
            {
                dependency.router.showClipInformationView(clipId: state.clipId,
                                                          itemId: currentItemId,
                                                          clipInformationViewCache: cache,
                                                          transitioningController: transitioningController)
            }
            return (nextState, .none)

        // MARK: Bar

        case let .barEventOccurred(event):
            return execute(action: event, state: nextState, dependency: dependency)

        // MARK: Gesture

        case .didTapView:
            nextState.isFullscreen = !state.isFullscreen
            return (nextState, .none)

        case .willBeginZoom:
            nextState.isFullscreen = true
            return (nextState, .none)

        // MARK: Modal Completion

        case let .tagsSelected(tagIds):
            guard let tagIds = tagIds else { return (state, .none) }
            switch dependency.clipCommandService.updateClips(having: [state.clipId], byReplacingTagsHaving: Array(tagIds)) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtUpdateTagsToClip)
            }
            return (nextState, .none)

        case let .albumsSelected(albumId):
            guard let albumId = albumId else { return (state, .none) }
            switch dependency.clipCommandService.updateAlbum(having: albumId, byAddingClipsHaving: [state.clipId]) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtAddClipToAlbum)
            }
            return (nextState, .none)

        case .modalCompleted:
            return (nextState, .none)

        // MARK: Alert Completion

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension ClipPreviewPageViewReducer {
    static func prepare(state: State, dependency: Dependency) -> (State, [Effect<Action>]) {
        let query: ClipQuery
        switch dependency.clipQueryService.queryClip(having: state.clipId) {
        case let .success(result):
            query = result

        case let .failure(error):
            fatalError("Failed to load clips: \(error.localizedDescription)")
        }
        let clipStream = query.clip
            .map { Action.clipUpdated($0) as Action? }
            .catch { _ in Just(Action.failedToLoadClip) }
        let queryEffect = Effect(clipStream, underlying: query, completeWith: .failedToLoadClip)

        return (state, [queryEffect])
    }
}

// MARK: - Router

extension ClipPreviewPageViewReducer {
    static func showTagSelectionModal(for clipId: Clip.Identity, selections: Set<Tag.Identity>, dependency: HasRouter) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                let isPresented = dependency.router.showTagSelectionModal(selections: selections) { tags in
                    let tagIds: Set<Tag.Identity>? = {
                        guard let tags = tags else { return nil }
                        return Set(tags.map({ $0.id }))
                    }()
                    promise(.success(.tagsSelected(tagIds)))
                }
                if !isPresented {
                    promise(.success(.modalCompleted(false)))
                }
            }
        }
        return Effect(stream)
    }

    static func showAlbumSelectionModal(for clipId: Clip.Identity, dependency: HasRouter) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                let isPresented = dependency.router.showAlbumSelectionModal { albumId in
                    promise(.success(.albumsSelected(albumId)))
                }
                if !isPresented {
                    promise(.success(.modalCompleted(false)))
                }
            }
        }
        return Effect(stream)
    }
}

// MARK: - Bar Event

extension ClipPreviewPageViewReducer {
    private static func execute(action: ClipPreviewPageBarEvent,
                                state: State,
                                dependency: Dependency) -> (State, [Effect<Action>]?)
    {
        var nextState = state

        switch action {
        case .backed:
            nextState.isDismissed = true
            return (nextState, .none)

        case .infoRequested:
            guard dependency.transitionLock.isFree else { return (nextState, .none) }
            if let currentItemId = state.currentItem?.id,
               let cache = dependency.informationViewCache,
               let transitioningController = dependency.clipInformationTransitioningController
            {
                dependency.router.showClipInformationView(clipId: state.clipId,
                                                          itemId: currentItemId,
                                                          clipInformationViewCache: cache,
                                                          transitioningController: transitioningController)
            }
            return (nextState, .none)

        case .browsed:
            if let url = state.currentItem?.url {
                dependency.router.open(url)
            }
            return (nextState, .none)

        case .addToAlbum:
            let effect = showAlbumSelectionModal(for: state.clipId, dependency: dependency)
            return (nextState, [effect])

        case .addTags:
            var effects: [Effect<Action>]?
            switch dependency.clipQueryService.readClipAndTags(for: [state.clipId]) {
            case let .success((_, tags)):
                effects = [
                    showTagSelectionModal(for: state.clipId, selections: Set(tags.map({ $0.id })), dependency: dependency)
                ]

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtUpdateTagsToClip)
            }
            return (nextState, effects)

        case .shared:
            return (state, .none)

        case .deleteClip:
            switch dependency.clipCommandService.deleteClips(having: [state.clipId]) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtDeleteClip)
            }
            return (nextState, .none)

        case .removeFromClip:
            guard let index = state.currentIndex,
                  let item = state.currentItem
            else {
                return (nextState, .none)
            }

            defer {
                nextState.currentPreloadTargets().forEach {
                    dependency.previewLoader.preloadPreview(imageId: $0)
                }
            }

            switch dependency.clipCommandService.deleteClipItem(item) {
            case .success:
                nextState.items = nextState.items.filter({ $0.id != item.id })

                guard !nextState.items.isEmpty else {
                    nextState.currentIndex = nil
                    nextState.isDismissed = true
                    return (nextState, .none)
                }

                if index < nextState.items.count {
                    nextState.currentIndex = index
                    nextState.pageChange = .forward
                } else if index - 1 >= 0 {
                    nextState.currentIndex = index - 1
                    nextState.pageChange = .reverse
                } else {
                    nextState.currentIndex = 0
                    nextState.pageChange = .forward
                }

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtRemoveItemFromClip)
            }
            return (nextState, .none)
        }
    }
}
