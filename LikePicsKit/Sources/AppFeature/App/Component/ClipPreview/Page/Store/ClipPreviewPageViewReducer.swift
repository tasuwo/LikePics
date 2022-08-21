//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import Environment
import Foundation
import LikePicsUIKit

typealias ClipPreviewPageViewDependency = HasRouter
    & HasClipCommandService
    & HasClipQueryService
    & HasClipItemInformationTransitioningController
    & HasTransitionLock
    & HasUserSettingStorage
    & HasClipPreviewPlayConfigurationStorage

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

        case let .playConfigUpdated(config: config):
            nextState.playConfiguration = config
            return (nextState, .none)

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

        case let .nextPageRequested(id):
            guard state.playingAt == id else { return (nextState, .none) }
            guard let nextIndexPath = state.clips.pickNextVisibleItem(from: state.currentIndexPath, by: state.playConfiguration) else { return (nextState, .none) }
            nextState.currentIndexPath = nextIndexPath
            nextState.isPageAnimated = state.playConfiguration.animation != .off
            nextState.pageChange = state.playConfiguration.animation.pageChange
            let stream = Deferred { [interval = state.playConfiguration.interval] in
                Just<Action?>(.nextPageRequested(id))
                    .delay(for: .seconds(interval), tolerance: 0, scheduler: RunLoop.main)
            }
            return (nextState, [Effect(stream)])

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
            guard let itemId = itemId, let indexPath = state.clips.indexPath(ofItemHaving: itemId) else {
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

        let playConfigStream = dependency.clipPreviewPlayConfigurationStorage.clipPreviewPlayConfiguration
            .map { Action.playConfigUpdated(config: $0) as Action? }
        let playConfigEffect = Effect(playConfigStream)
        effects.append(playConfigEffect)

        return (state, effects)
    }
}

// MARK: - Filter

extension ClipPreviewPageViewReducer {
    private static func performFilter(clips: [Clip],
                                      previousState: State) -> (State, [Effect<Action>])
    {
        performFilter(clips: clips,
                      isSomeItemsHidden: previousState.clips.isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(isSomeItemsHidden: Bool,
                                      previousState: State) -> (State, [Effect<Action>])
    {
        performFilter(clips: previousState.clips.value,
                      isSomeItemsHidden: isSomeItemsHidden,
                      previousState: previousState)
    }

    private static func performFilter(clips: [Clip],
                                      isSomeItemsHidden: Bool,
                                      previousState: State) -> (State, [Effect<Action>])
    {
        var nextState = previousState

        let newClips = PreviewingClips(clips: clips, isSomeItemsHidden: isSomeItemsHidden)
        let result = ClipPreviewIndexCoordinator.coordinate(previousIndexPath: previousState.currentIndexPath,
                                                            previousSelectedClip: previousState.currentClip,
                                                            previousSelectedItem: previousState.currentItem,
                                                            newPreviewingClips: newClips)
        nextState.clips = newClips
        nextState = nextState.updated(by: result)

        return (nextState, [])
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

        case .played:
            let id = UUID()
            nextState.playingAt = id
            let stream = Deferred { [interval = state.playConfiguration.interval] in
                Just<Action?>(.nextPageRequested(id))
                    .delay(for: .seconds(interval), tolerance: 0, scheduler: RunLoop.main)
            }
            return (nextState, [Effect(stream)])

        case .playConfigRequested:
            nextState.modal = .playConfig(id: UUID())
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

            switch dependency.clipCommandService.deleteClips(having: [currentClipId]) {
            case .success:
                let newClips = nextState.clips.removedClip(atIndex: state.currentIndexPath.clipIndex)
                let result = ClipPreviewIndexCoordinator.coordinate(previousIndexPath: state.currentIndexPath,
                                                                    previousSelectedClip: state.currentClip,
                                                                    previousSelectedItem: state.currentItem,
                                                                    newPreviewingClips: newClips)
                nextState.clips = newClips
                nextState = nextState.updated(by: result)

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtDeleteClip)
            }
            return (nextState, .none)

        case .removeFromClip:
            guard let item = state.currentItem else {
                return (nextState, .none)
            }

            switch dependency.clipCommandService.deleteClipItem(item) {
            case .success:
                let newClips = nextState.clips.removedClipItem(atIndexPath: state.currentIndexPath)
                let result = ClipPreviewIndexCoordinator.coordinate(previousIndexPath: state.currentIndexPath,
                                                                    previousSelectedClip: state.currentClip,
                                                                    previousSelectedItem: state.currentItem,
                                                                    newPreviewingClips: newClips)
                nextState.clips = newClips
                nextState = nextState.updated(by: result)

            case .failure:
                nextState.alert = .error(L10n.clipCollectionErrorAtRemoveItemFromClip)
            }
            return (nextState, .none)
        }
    }
}

private extension ClipPreviewPlayConfiguration.Animation {
    var pageChange: ClipPreviewPageViewState.PageChange {
        switch self {
        case .forward, .off:
            return .forward

        case .reverse:
            return .reverse
        }
    }
}
