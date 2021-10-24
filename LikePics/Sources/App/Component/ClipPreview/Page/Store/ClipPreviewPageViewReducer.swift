//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import Foundation

typealias ClipPreviewPageViewDependency = HasRouter
    & HasClipCommandService
    & HasClipQueryService
    & HasClipItemInformationTransitioningController
    & HasTransitionLock
    & HasUserSettingStorage

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

        case let .indicesCalculated(indexByClipId: indexByClipId,
                                    indexPathByClipItemId: indexPathByClipItemId):
            guard indexByClipId != nextState.indexByClipId
                || indexPathByClipItemId != nextState.indexPathByClipItemId
            else {
                return (nextState, .none)
            }
            nextState.indexByClipId = indexByClipId
            nextState.indexPathByClipItemId = indexPathByClipItemId
            return (nextState, .none)

        case let .pageChanged(indexPath: indexPath):
            nextState.pageChange = nil
            nextState.currentIndexPath = indexPath
            return (nextState, .none)

        case .failedToLoadClip:
            nextState.isDismissed = true
            return (nextState, .none)

        case let .clipsUpdated(clips):
            return Self.performFilter(clips: clips, previousState: state)

        case let .settingUpdated(isSomeItemsHidden: isSomeItemsHidden):
            return Self.performFilter(isSomeItemsHidden: isSomeItemsHidden, previousState: state)

        // MARK: Transition

        case .clipInformationViewPresented:
            if let currentClipId = state.currentClip?.id,
               let currentItemId = state.currentItem?.id,
               let transitioningController = dependency.clipItemInformationTransitioningController
            {
                dependency.router.showClipInformationView(clipId: currentClipId,
                                                          itemId: currentItemId,
                                                          transitioningController: transitioningController)
            }
            return (nextState, .none)

        // MARK: Bar

        case let .barEventOccurred(event):
            return Self.execute(action: event, state: nextState, dependency: dependency)

        // MARK: Modal Completion

        case let .tagsSelected(tagIds):
            nextState.modal = nil

            guard let currentClipId = state.currentClip?.id,
                  let tagIds = tagIds else { return (nextState, .none) }

            switch dependency.clipCommandService.updateClips(having: [currentClipId], byReplacingTagsHaving: Array(tagIds)) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtUpdateTagsToClip)
            }
            nextState.modal = nil
            return (nextState, .none)

        case let .albumsSelected(albumId):
            nextState.modal = nil

            guard let currentClipId = state.currentClip?.id,
                  let albumId = albumId else { return (nextState, .none) }

            switch dependency.clipCommandService.updateAlbum(having: albumId, byAddingClipsHaving: [currentClipId]) {
            case .success: ()

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtAddClipToAlbum)
            }
            nextState.modal = nil
            return (nextState, .none)

        case let .itemRequested(itemId):
            guard let itemId = itemId, let indexPath = state.indexPathByClipItemId[itemId] else {
                return (nextState, .none)
            }
            nextState.isPageAnimated = false
            nextState.currentIndexPath = indexPath
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
        var effects: [Effect<Action>] = []

        switch state.query {
        case let .clips(source):
            let stream = source.fetchStream(by: dependency.clipQueryService)
            let clipsStream = stream.clipsStream
                .map { Action.clipsUpdated($0) as Action? }
                .catch { _ in Just(Action.failedToLoadClip) }
            let queryEffect = Effect(clipsStream, underlying: stream.query, completeWith: .failedToLoadClip)
            effects.append(queryEffect)

        case .searchResult:
            break
        }

        let settingsStream = dependency.userSettingStorage.showHiddenItems
            .map { Action.settingUpdated(isSomeItemsHidden: !$0) as Action? }
        let settingsEffect = Effect(settingsStream)
        effects.append(settingsEffect)

        return (state, effects)
    }
}

// MARK: - Filter

extension ClipPreviewPageViewReducer {
    private static func performFilter(clips: [Clip],
                                      previousState: State) -> (State, [Effect<Action>])
    {
        performFilter(clips: clips,
                      isSomeItemsHidden: previousState.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool,
                                      previousState: State) -> (State, [Effect<Action>])
    {
        performFilter(clips: previousState.clips,
                      isSomeItemsHidden: isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(clips: [Clip],
                                      isSomeItemsHidden: Bool,
                                      previousState: State) -> (State, [Effect<Action>])
    {
        var nextState = previousState

        let calcStream = Deferred {
            Future<Action?, Never> { [clips] promise in
                var indexByClipId: [Clip.Identity: Int] = [:]
                var indexPathByClipItemId: [ClipItem.Identity: ClipCollection.IndexPath] = [:]
                DispatchQueue.global().async {
                    zip(clips.indices, clips).forEach { clipIndex, clip in
                        indexByClipId[clip.id] = clipIndex
                        zip(clip.items.indices, clip.items).forEach { itemIndex, item in
                            indexPathByClipItemId[item.id] = ClipCollection.IndexPath(clipIndex: clipIndex, itemIndex: itemIndex)
                        }
                    }

                    promise(.success(.indicesCalculated(indexByClipId: indexByClipId,
                                                        indexPathByClipItemId: indexPathByClipItemId)))
                }
            }
        }

        // 差分があった場合のみ後続で計算を行う
        guard previousState.isSomeItemsHidden != isSomeItemsHidden
            || previousState.clips != clips
        else {
            return (previousState, [Effect(calcStream)])
        }

        var filteredClipIds: [Clip.Identity] = []
        var newClipIndex: Int?

        for (index, clip) in zip(clips.indices, clips) {
            if isSomeItemsHidden {
                if clip.isHidden == false {
                    filteredClipIds.append(clip.id)
                }
            } else {
                filteredClipIds.append(clip.id)
            }

            if previousState.currentClip?.id == clip.id {
                newClipIndex = index
            }
        }

        nextState.clips = clips
        nextState.filteredClipIds = Set(filteredClipIds)
        nextState.isSomeItemsHidden = isSomeItemsHidden

        // 元々フォーカスしていた Clip や Item が存在した場合は、IndexPath の調整を行う
        guard let previousClip = previousState.currentClip,
              let previousItem = previousState.currentItem
        else {
            return (nextState, [Effect(calcStream)])
        }

        if let clipIndex = newClipIndex {
            if filteredClipIds.contains(previousClip.id) {
                // 元々フォーカスしていた Clip が存在し、表示可能だった場合
                if let itemIndex = previousClip.items.firstIndex(of: previousItem) {
                    // 元々フォーカスしていた Item が存在した場合
                    nextState.isPageAnimated = false
                    nextState.currentIndexPath = .init(clipIndex: clipIndex, itemIndex: itemIndex)
                } else {
                    // 元々フォーカスしていた Item が存在しなかった場合
                    nextState.isPageAnimated = true
                    nextState.pageChange = .reverse
                    nextState.currentIndexPath = .init(clipIndex: clipIndex, itemIndex: 0)
                }
            } else {
                // 元々フォーカスしていた Clip が存在し、表示不可だった場合
                if let indexPath = indexPath(after: clipIndex, clips: clips, filteredClipIds: Set(filteredClipIds)) {
                    // 前方向に探索
                    nextState.isPageAnimated = true
                    nextState.pageChange = .forward
                    nextState.currentIndexPath = indexPath
                } else if let indexPath = indexPath(before: clipIndex, clips: clips, filteredClipIds: Set(filteredClipIds)) {
                    // 後方向に探索
                    nextState.isPageAnimated = true
                    nextState.pageChange = .reverse
                    nextState.currentIndexPath = indexPath
                } else {
                    // 表示できるクリップが存在しないため、閉じる
                    nextState.isDismissed = true
                }
            }
        } else {
            let previousClipIndex = previousState.currentIndexPath.clipIndex
            if nextState.clips.indices.contains(previousClipIndex),
               nextState.filteredClipIds.contains(nextState.clips[previousClipIndex].id)
            {
                // 前回の位置に該当するクリップが表示可能だった
                nextState.currentIndexPath = .init(clipIndex: previousClipIndex, itemIndex: 0)
                nextState.pageChange = .forward
            } else {
                // 前回の位置に該当するクリップが表示不可だった
                nextState = transitToClip(around: previousClipIndex, state: nextState)
            }
        }

        return (nextState, [Effect(calcStream)])
    }

    static func indexPath(after clipIndex: Int, clips: [Clip], filteredClipIds: Set<Clip.Identity>) -> ClipCollection.IndexPath? {
        guard clipIndex + 1 < clips.count else { return nil }
        for clipIndex in clipIndex + 1 ... clips.count - 1 {
            if filteredClipIds.contains(clips[clipIndex].id) {
                return .init(clipIndex: clipIndex, itemIndex: 0)
            }
        }
        return nil
    }

    static func indexPath(before clipIndex: Int, clips: [Clip], filteredClipIds: Set<Clip.Identity>) -> ClipCollection.IndexPath? {
        guard clipIndex - 1 >= 0 else { return nil }
        for clipIndex in (0 ... clipIndex - 1).reversed() {
            if filteredClipIds.contains(clips[clipIndex].id) {
                return .init(clipIndex: clipIndex, itemIndex: clips[clipIndex].items.count - 1)
            }
        }
        return nil
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
            if let currentClipId = state.currentClip?.id,
               let currentItemId = state.currentItem?.id,
               let transitioningController = dependency.clipItemInformationTransitioningController
            {
                dependency.router.showClipInformationView(clipId: currentClipId,
                                                          itemId: currentItemId,
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
            guard let currentClipId = state.currentClip?.id else {
                nextState.alert = .error(L10n.clipCollectionErrorAtUpdateTagsToClip)
                return (nextState, .none)
            }

            switch dependency.clipQueryService.readClipAndTags(for: [currentClipId]) {
            case let .success((_, tags)):
                nextState.modal = .tagSelection(id: UUID(), tagIds: Set(tags.map({ $0.id })))

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtUpdateTagsToClip)
            }
            return (nextState, .none)

        case .shared:
            return (state, .none)

        case .deleteClip:
            guard let currentClipId = state.currentClip?.id else {
                nextState.alert = .error(L10n.clipCollectionErrorAtUpdateTagsToClip)
                return (nextState, .none)
            }

            let clipIndex = state.currentIndexPath.clipIndex
            let itemIndex = state.currentIndexPath.itemIndex

            guard nextState.clips.indices.contains(clipIndex),
                  nextState.clips[clipIndex].items.indices.contains(itemIndex)
            else {
                return (nextState, .none)
            }

            switch dependency.clipCommandService.deleteClips(having: [currentClipId]) {
            case .success:
                nextState.clips.remove(at: clipIndex)

                if nextState.clips.indices.contains(clipIndex),
                   nextState.filteredClipIds.contains(nextState.clips[clipIndex].id)
                {
                    // 現在位置に該当するクリップが表示可能だった
                    nextState.currentIndexPath = .init(clipIndex: clipIndex, itemIndex: 0)
                    nextState.pageChange = .forward
                } else {
                    // 現在位置に該当するクリップが表示不可だった
                    nextState = transitToClip(around: clipIndex, state: nextState)
                }

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtDeleteClip)
            }
            return (nextState, .none)

        case .removeFromClip:
            guard let item = state.currentItem else {
                return (nextState, .none)
            }

            let clipIndex = state.currentIndexPath.clipIndex
            let itemIndex = state.currentIndexPath.itemIndex

            guard nextState.clips.indices.contains(clipIndex),
                  nextState.clips[clipIndex].items.indices.contains(itemIndex)
            else {
                return (nextState, .none)
            }

            switch dependency.clipCommandService.deleteClipItem(item) {
            case .success: ()
                nextState.clips[clipIndex] = state.clips[clipIndex].removedItem(at: itemIndex)

                guard !nextState.clips[clipIndex].items.isEmpty else {
                    nextState.isDismissed = true
                    return (nextState, .none)
                }

                if itemIndex < nextState.clips[clipIndex].items.count {
                    // 現在位置に該当するアイテムが存在する
                    nextState.currentIndexPath = .init(clipIndex: clipIndex, itemIndex: itemIndex)
                    nextState.pageChange = .forward
                } else if itemIndex - 1 >= 0 {
                    // 1つ前のアイテムが存在する
                    nextState.currentIndexPath = .init(clipIndex: clipIndex, itemIndex: itemIndex - 1)
                    nextState.pageChange = .reverse
                } else {
                    nextState = transitToClip(around: clipIndex, state: nextState)
                }

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtRemoveItemFromClip)
            }
            return (nextState, .none)
        }
    }

    private static func transitToClip(around clipIndex: Int, state: State) -> State {
        var nextState = state
        if let indexPath = indexPath(after: clipIndex, clips: nextState.clips, filteredClipIds: nextState.filteredClipIds) {
            // 前方向に探索
            nextState.isPageAnimated = true
            nextState.pageChange = .forward
            nextState.currentIndexPath = indexPath
        } else if let indexPath = indexPath(before: clipIndex, clips: nextState.clips, filteredClipIds: nextState.filteredClipIds) {
            // 後方向に探索
            nextState.isPageAnimated = true
            nextState.pageChange = .reverse
            nextState.currentIndexPath = indexPath
        } else {
            // 表示できるクリップが存在しないため、閉じる
            nextState.isDismissed = true
        }
        return nextState
    }
}
