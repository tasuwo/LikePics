//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Environment
import LikePicsUIKit

typealias ClipPreviewPageBarDependency = HasImageQueryService
    & HasTransitionLock

struct ClipPreviewPageBarReducer: Reducer {
    typealias Dependency = ClipPreviewPageBarDependency
    typealias Action = ClipPreviewPageBarAction
    typealias State = ClipPreviewPageBarState

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case let .sizeClassChanged(isVerticalSizeClassCompact: isVerticalSizeClassCompact):
            nextState.isVerticalSizeClassCompact = isVerticalSizeClassCompact
            nextState = nextState.updatingAppearance()
            return (nextState, .none)

        // MARK: State Observation

        case let .updatedCurrentIndex(currentIndex):
            nextState.currentIndex = currentIndex
            nextState = nextState.updatingAppearance()
            return (nextState, .none)

        case let .updatedClipItems(clipItems):
            nextState.clipItems = clipItems
            nextState = nextState.updatingAppearance()
            return (nextState, .none)

        case let .updatedPlaying(isPlaying):
            nextState.isPlaying = isPlaying
            nextState = nextState.updatingAppearance()
            return (nextState, .none)

        // MARK: Gesture

        case .didTapView:
            nextState.isFullscreen = !state.isFullscreen
            nextState = nextState.updatingAppearance()
            return (nextState, .none)

        case .willBeginZoom:
            nextState.isFullscreen = true
            nextState = nextState.updatingAppearance()
            return (nextState, .none)

        // MARK: Bar Button

        case .backButtonTapped,
            .listButtonTapped,
            .infoButtonTapped,
            .browseButtonTapped,
            .playButtonTapped,
            .pauseButtonTapped,
            .playConfigButtonTapped:
            // 画面遷移中であった場合、ボタン操作は無視する
            guard dependency.transitionLock.isFree else { return (nextState, .none) }
            return (nextState, .none)

        case .addButtonTapped:
            // 画面遷移中であった場合、ボタン操作は無視する
            guard dependency.transitionLock.isFree else { return (nextState, .none) }
            nextState.alert = .addition
            return (nextState, .none)

        case .shareButtonTapped:
            // 画面遷移中であった場合、ボタン操作は無視する
            guard dependency.transitionLock.isFree else { return (nextState, .none) }
            if nextState.clipItems.count > 1 {
                nextState.alert = .shareTargetSelection
                return (nextState, .none)
            } else {
                let imageIds = state.clipItems.map({ $0.imageId })
                nextState.alert = .share(imageIds: imageIds)
                return (nextState, .none)
            }

        case .deleteButtonTapped:
            // 画面遷移中であった場合、ボタン操作は無視する
            guard dependency.transitionLock.isFree else { return (nextState, .none) }
            nextState.alert = .deletion(includesRemoveFromClip: nextState.clipItems.count > 1)
            return (nextState, .none)

        // MARK: Alert Completion

        case .alertDeleteClipConfirmed,
            .alertDeleteClipItemConfirmed,
            .alertTagAdditionConfirmed,
            .alertAlbumAdditionConfirmed,
            .alertShareDismissed,
            .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)

        case .alertShareItemConfirmed:
            guard let index = state.currentIndex, state.clipItems.indices.contains(index) else {
                return (nextState, .none)
            }
            let currentItem = state.clipItems[index]
            nextState.alert = .share(imageIds: [currentItem.imageId])
            return (nextState, .none)

        case .alertShareClipConfirmed:
            let imageIds = state.clipItems.map({ $0.imageId })
            nextState.alert = .share(imageIds: imageIds)
            return (nextState, .none)
        }
    }
}

extension ClipPreviewPageBarState {
    fileprivate func updatingAppearance() -> Self {
        var nextState = self

        if nextState.isFullscreen {
            nextState.isToolBarHidden = true
            nextState.isNavigationBarHidden = true
            nextState.isPageCounterHidden = true
            return nextState
        }

        let existsUrlAtCurrentItem: Bool = {
            guard let index = nextState.currentIndex, nextState.clipItems.indices.contains(index) else { return false }
            return nextState.clipItems[index].url != nil
        }()

        nextState.isToolBarHidden = isVerticalSizeClassCompact
        nextState.isNavigationBarHidden = false
        nextState.isPageCounterHidden = false

        if nextState.isToolBarHidden {
            nextState.toolBarItems = []
            nextState.leftBarButtonItems = [
                .init(kind: .back, isEnabled: true)
            ]
            nextState.rightBarButtonItems = [
                .init(kind: .option, isEnabled: true),
                nextState.isPlaying ? .init(kind: .pause, isEnabled: true) : .init(kind: .play, isEnabled: true),
                .init(kind: .add, isEnabled: true),
                .init(kind: .list, isEnabled: true),
                .init(kind: .share, isEnabled: true),
                .init(kind: .delete, isEnabled: true),
            ]
        } else {
            nextState.toolBarItems = [
                nextState.isPlaying ? .init(kind: .pause, isEnabled: true) : .init(kind: .play, isEnabled: true),
                .init(kind: .add, isEnabled: true),
                .init(kind: .list, isEnabled: true),
                .init(kind: .share, isEnabled: true),
                .init(kind: .delete, isEnabled: true),
            ]
            nextState.leftBarButtonItems = [
                .init(kind: .back, isEnabled: true)
            ]
            nextState.rightBarButtonItems = [.init(kind: .option, isEnabled: true)]
        }

        nextState.optionMenuItems = [
            .info,
            existsUrlAtCurrentItem ? .browse : nil,
            .playConfig,
        ].compactMap { $0 }

        return nextState
    }
}
