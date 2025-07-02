//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import CompositeKit
import Domain
import Environment
import Foundation

typealias ClipMergeViewDependency = HasClipCommandService
    & HasClipQueryService
    & HasModalNotificationCenter
    & HasRouter

struct ClipMergeViewReducer: Reducer {
    typealias Dependency = ClipMergeViewDependency
    typealias State = ClipMergeViewState
    typealias Action = ClipMergeViewAction

    func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            nextState = Self.prepareState(initialState: state, dependency: dependency)
            return (nextState, .none)

        // MARK: NavigationBar

        case .saveButtonTapped:
            let itemIds = state.items.map({ $0.id })
            let tagIds = state.tags.map({ $0.id })
            switch dependency.clipCommandService.mergeClipItems(
                itemIds: itemIds,
                tagIds: tagIds,
                siteUrl: state.overwriteSiteUrl,
                isHidden: state.shouldSaveAsHiddenItem,
                inClipsHaving: Array(state.sourceClipIds)
            )
            {
            case .success:
                return Self.dismiss(isCompleted: true, state: state, dependency: dependency)

            case .failure:
                nextState.alert = .error(L10n.clipMergeViewErrorAtMerge)
                return (nextState, .none)
            }

        case .cancelButtonTapped:
            return Self.dismiss(isCompleted: false, state: state, dependency: dependency)

        // MARK: Button Action

        case .tagAdditionButtonTapped:
            nextState.modal = .tagSelection(id: UUID(), tagIds: Set(state.tags.map({ $0.id })))
            return (nextState, .none)

        case let .tagDeleteButtonTapped(tagId):
            nextState.tags = state.tags.filter({ $0.id != tagId })
            return (nextState, .none)

        case let .editedOverwriteSiteUrl(url):
            nextState.overwriteSiteUrl = url
            return (nextState, .none)

        case let .shouldSaveAsHiddenItem(isHidden):
            nextState.shouldSaveAsHiddenItem = isHidden
            return (nextState, .none)

        case let .siteUrlButtonTapped(url):
            dependency.router.open(url)
            return (state, .none)

        // MARK: CollectionView

        case let .itemReordered(items):
            nextState.items = items
            return (nextState, .none)

        // MARK: Modal Completion

        case let .tagsSelected(tags):
            nextState.modal = nil

            guard let tags = tags else { return (nextState, .none) }

            let sortedTags = Array(tags).sorted(by: { $0.name < $1.name })
            nextState.tags = sortedTags

            return (nextState, .none)

        case .modalCompleted:
            nextState.modal = nil
            return (nextState, .none)

        // MARK: Alert Completion

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)

        // MARK: Transition

        case .didDismissedManually:
            return Self.dismiss(isCompleted: false, state: state, dependency: dependency)
        }
    }
}

// MARK: - Dismiss

extension ClipMergeViewReducer {
    private static func dismiss(isCompleted: Bool, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state
        dependency.modalNotificationCenter.post(id: state.id, name: .clipMergeModal, userInfo: [.clipMergeCompleted: isCompleted])
        nextState.isDismissed = true
        return (nextState, .none)
    }
}

// MARK: - Preparation

extension ClipMergeViewReducer {
    static func prepareState(initialState: State, dependency: Dependency) -> State {
        let tags: [Tag]
        switch dependency.clipQueryService.readClipAndTags(for: Array(initialState.sourceClipIds)) {
        case let .success((_, fetchedTags)):
            tags = fetchedTags

        case let .failure(error):
            fatalError("Failed to load tags: \(error.localizedDescription)")
        }

        var nextState = initialState
        nextState.tags = tags

        return nextState
    }
}
