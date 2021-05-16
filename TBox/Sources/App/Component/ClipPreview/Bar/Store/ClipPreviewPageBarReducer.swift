//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine

typealias ClipPreviewPageBarDependency = HasClipPreviewPageBarDelegate
    & HasImageQueryService
    & HasTransitionLock

struct ClipPreviewPageBarReducer: Reducer {
    typealias Dependency = ClipPreviewPageBarDependency
    typealias Action = ClipPreviewPageBarAction
    typealias State = ClipPreviewPageBarState

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        let stream = Deferred {
            Future<Action?, Never> { promise in
                if let event = action.mapToEvent() {
                    dependency.clipPreviewPageBarDelegate?.didTriggered(event)
                }
                promise(.success(nil))
            }
        }
        let eventEffect = Effect(stream)

        switch action {
        // MARK: View Life-Cycle

        case let .sizeClassChanged(isVerticalSizeClassCompact: isVerticalSizeClassCompact):
            nextState.isVerticalSizeClassCompact = isVerticalSizeClassCompact
            nextState = nextState.updatingAppearance()
            return (nextState, [eventEffect])

        // MARK: State Observation

        case let .stateChanged(state):
            nextState.parentState = state
            return (nextState, [eventEffect])

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
             .infoButtonTapped,
             .browseButtonTapped:
            // 画面遷移中であった場合、ボタン操作は無視する
            guard dependency.transitionLock.isFree else { return (nextState, .none) }
            return (nextState, [eventEffect])

        case .addButtonTapped:
            // 画面遷移中であった場合、ボタン操作は無視する
            guard dependency.transitionLock.isFree else { return (nextState, .none) }
            nextState.alert = .addition
            return (nextState, [eventEffect])

        case .shareButtonTapped:
            // 画面遷移中であった場合、ボタン操作は無視する
            guard dependency.transitionLock.isFree else { return (nextState, .none) }
            if nextState.parentState.items.count > 1 {
                nextState.alert = .shareTargetSelection
                return (nextState, [eventEffect])
            } else {
                let imageIds = state.parentState.items.map({ $0.imageId })
                nextState.alert = .share(imageIds: imageIds)
                return (nextState, [eventEffect])
            }

        case .deleteButtonTapped:
            // 画面遷移中であった場合、ボタン操作は無視する
            guard dependency.transitionLock.isFree else { return (nextState, .none) }
            nextState.alert = .deletion(includesRemoveFromClip: nextState.parentState.items.count > 1)
            return (nextState, [eventEffect])

        // MARK: Alert Completion

        case .alertDeleteClipConfirmed,
             .alertDeleteClipItemConfirmed,
             .alertTagAdditionConfirmed,
             .alertAlbumAdditionConfirmed,
             .alertShareDismissed,
             .alertDismissed:
            nextState.alert = nil
            return (nextState, [eventEffect])

        case .alertShareItemConfirmed:
            guard let index = state.parentState.currentIndex else {
                return (nextState, [eventEffect])
            }
            let currentItem = state.parentState.items[index]
            nextState.alert = .share(imageIds: [currentItem.imageId])
            return (nextState, [eventEffect])

        case .alertShareClipConfirmed:
            let imageIds = state.parentState.items.map({ $0.imageId })
            nextState.alert = .share(imageIds: imageIds)
            return (nextState, [eventEffect])
        }
    }
}

private extension ClipPreviewPageBarState {
    func updatingAppearance() -> Self {
        var nextState = self

        if nextState.isFullscreen {
            nextState.isToolBarHidden = true
            nextState.isNavigationBarHidden = true
            return nextState
        }

        let existsUrlAtCurrentItem: Bool = {
            guard let index = nextState.parentState.currentIndex else { return false }
            return nextState.parentState.items[index].url != nil
        }()

        nextState.isToolBarHidden = isVerticalSizeClassCompact
        nextState.isNavigationBarHidden = false

        if nextState.isToolBarHidden {
            nextState.toolBarItems = []
            nextState.leftBarButtonItems = [.init(kind: .back, isEnabled: true)]
            nextState.rightBarButtonItems = [
                .init(kind: .browse, isEnabled: existsUrlAtCurrentItem),
                .init(kind: .add, isEnabled: true),
                .init(kind: .share, isEnabled: true),
                .init(kind: .delete, isEnabled: true)
            ]
        } else {
            nextState.toolBarItems = [
                .init(kind: .browse, isEnabled: existsUrlAtCurrentItem),
                .init(kind: .add, isEnabled: true),
                .init(kind: .share, isEnabled: true),
                .init(kind: .delete, isEnabled: true)
            ]
            nextState.leftBarButtonItems = [.init(kind: .back, isEnabled: true)]
            nextState.rightBarButtonItems = [.init(kind: .info, isEnabled: true)]
        }

        return nextState
    }
}

private extension ClipPreviewPageBarAction {
    func mapToEvent() -> ClipPreviewPageBarEvent? {
        switch self {
        case .backButtonTapped:
            return .backed

        case .infoButtonTapped:
            return .infoRequested

        case .browseButtonTapped:
            return .browsed

        case .alertDeleteClipConfirmed:
            return .deleteClip

        case .alertDeleteClipItemConfirmed:
            return .removeFromClip

        case .alertTagAdditionConfirmed:
            return .addTags

        case .alertAlbumAdditionConfirmed:
            return .addToAlbum

        case let .alertShareDismissed(succeeded):
            return .shared(succeeded)

        default:
            return nil
        }
    }
}
