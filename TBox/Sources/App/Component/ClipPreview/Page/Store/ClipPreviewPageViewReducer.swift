//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain
import ForestKit

typealias ClipPreviewPageViewDependency = HasRouter
    & HasClipCommandService
    & HasClipQueryService
    & HasClipItemInformationTransitioningController
    & HasClipItemInformationViewCaching
    & HasPreviewLoader
    & HasTransitionLock

struct ClipPreviewPageViewReducer: Reducer {
    typealias Dependency = ClipPreviewPageViewDependency
    typealias State = ClipPreviewPageViewState
    typealias Action = ClipPreviewPageViewAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        if !nextState.isPageAnimated {
            nextState.isPageAnimated = true
        }

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            return Self.prepare(state: nextState, dependency: dependency)

        // MARK: State Observation

        case let .pageChanged(index: index):
            nextState.pageChange = nil
            nextState.currentIndex = index
            return (nextState, [Self.preloadEffect(state: nextState, dependency: dependency)])

        case let .clipUpdated(clip):
            guard !clip.items.isEmpty else {
                nextState.isDismissed = true
                return (nextState, [Self.preloadEffect(state: nextState, dependency: dependency)])
            }

            nextState.items = clip.items.sorted(by: { $0.clipIndex < $1.clipIndex })

            if let initialItem = state.initialItemId,
               let newIndex = nextState.items.firstIndex(where: { $0.id == initialItem })
            {
                nextState.currentIndex = newIndex
                nextState.initialItemId = nil
                return (nextState, [Self.preloadEffect(state: nextState, dependency: dependency)])
            }

            guard let previousItemId = state.currentItem?.id else {
                nextState.currentIndex = 0
                return (nextState, [Self.preloadEffect(state: nextState, dependency: dependency)])
            }

            if let newIndex = nextState.items.firstIndex(where: { $0.id == previousItemId }) {
                nextState.currentIndex = newIndex
                return (nextState, [Self.preloadEffect(state: nextState, dependency: dependency)])
            } else {
                nextState.currentIndex = 0
                return (nextState, [Self.preloadEffect(state: nextState, dependency: dependency)])
            }

        case .failedToLoadClip:
            nextState.isDismissed = true
            return (nextState, .none)

        // MARK: Transition

        case .clipInformationViewPresented:
            if let currentItemId = state.currentItem?.id,
               let cache = dependency.informationViewCache,
               let transitioningController = dependency.clipItemInformationTransitioningController
            {
                dependency.router.showClipInformationView(clipId: state.clipId,
                                                          itemId: currentItemId,
                                                          clipInformationViewCache: cache,
                                                          transitioningController: transitioningController)
            }
            return (nextState, .none)

        // MARK: Bar

        case let .barEventOccurred(event):
            return Self.execute(action: event, state: nextState, dependency: dependency)

        // MARK: Modal Completion

        case let .tagsSelected(tagIds):
            nextState.modal = nil

            guard let tagIds = tagIds else { return (nextState, .none) }

            switch dependency.clipCommandService.updateClips(having: [state.clipId], byReplacingTagsHaving: Array(tagIds)) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtUpdateTagsToClip)
            }
            nextState.modal = nil
            return (nextState, .none)

        case let .albumsSelected(albumId):
            nextState.modal = nil

            guard let albumId = albumId else { return (nextState, .none) }

            switch dependency.clipCommandService.updateAlbum(having: albumId, byAddingClipsHaving: [state.clipId]) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtAddClipToAlbum)
            }
            nextState.modal = nil
            return (nextState, .none)

        case let .itemRequested(itemId):
            guard let newIndex = nextState.items.firstIndex(where: { $0.id == itemId }) else {
                return (nextState, .none)
            }
            nextState.isPageAnimated = false
            nextState.currentIndex = newIndex
            nextState.modal = nil
            return (nextState, .none)

        case .modalCompleted:
            nextState.modal = nil
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

// MARK: - Bar Event

extension ClipPreviewPageViewReducer {
    private static func execute(action: ClipPreviewPageBarEvent,
                                state: State,
                                dependency: Dependency) -> (State, [Effect<Action>]?)
    {
        var nextState = state

        // 画面遷移中であった場合、ボタン操作は無視する
        guard dependency.transitionLock.isFree else { return (nextState, .none) }

        switch action {
        case .backed:
            nextState.isDismissed = true
            return (nextState, .none)

        case .listed:
            nextState.modal = .clipItemList(id: UUID())
            return (nextState, .none)

        case .infoRequested:
            if let currentItemId = state.currentItem?.id,
               let cache = dependency.informationViewCache,
               let transitioningController = dependency.clipItemInformationTransitioningController
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
            nextState.modal = .albumSelection(id: UUID())
            return (nextState, .none)

        case .addTags:
            switch dependency.clipQueryService.readClipAndTags(for: [state.clipId]) {
            case let .success((_, tags)):
                nextState.modal = .tagSelection(id: UUID(), tagIds: Set(tags.map({ $0.id })))

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtUpdateTagsToClip)
            }
            return (nextState, .none)

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
            return (nextState, [Self.preloadEffect(state: nextState, dependency: dependency)])
        }
    }
}

// MARK: - Preload

extension ClipPreviewPageViewReducer {
    private static func preloadEffect(state: State, dependency: Dependency) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                state.currentPreloadTargets().forEach {
                    dependency.previewLoader.preloadPreview(imageId: $0)
                    promise(.success(nil))
                }
            }
        }
        return Effect(stream)
            // アニメーション中に画像が再読み込みされるとアニメーションがかくつくので、
            // あえて読み込みを遅延させる
            .delay(for: 0.3, scheduler: DispatchQueue.global())
    }
}
