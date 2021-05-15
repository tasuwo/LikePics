//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

typealias ClipPreviewPageViewCacheDependency = HasClipInformationViewCaching

struct ClipPreviewPageViewCacheReducer: Reducer {
    typealias Dependency = ClipPreviewPageViewCacheDependency
    typealias Action = ClipPreviewPageViewCacheAction
    typealias State = ClipPreviewPageViewCacheState

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        switch action {
        // MARK: View Life-Cycle

        case .viewWillDisappear:
            dependency.informationViewCache?.stopUpdating()
            return (state, .none)

        case .viewDidAppear:
            dependency.informationViewCache?.insertCachingViewHierarchyIfNeeded()
            guard let itemId = state.itemId else { return (state, .none) }
            dependency.informationViewCache?.startUpdating(clipId: state.clipId,
                                                           itemId: itemId)
            return (state, .none)

        // MARK: Transition

        case let .pageChanged(clipId, itemId):
            dependency.informationViewCache?.startUpdating(clipId: clipId, itemId: itemId)
            var nextState = state
            nextState.clipId = clipId
            nextState.itemId = itemId
            return (nextState, .none)
        }
    }
}
