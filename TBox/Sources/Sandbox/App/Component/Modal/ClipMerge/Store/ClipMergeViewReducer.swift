//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias ClipMergeViewDependency = HasRouter
    & HasClipQueryService
    & HasClipCommandService
    & HasClipMergeModalSubscription

enum ClipMergeViewReducer: Reducer {
    typealias Dependency = ClipMergeViewDependency
    typealias State = ClipMergeViewState
    typealias Action = ClipMergeViewAction

    static func execute(action: Action, state: State, dependency: Dependency) -> (State, [Effect<Action>]?) {
        var nextState = state

        switch action {
        // MARK: View Life-Cycle

        case .viewDidLoad:
            nextState = prepareState(initialState: state, dependency: dependency)
            return (nextState, .none)

        // MARK: NavigationBar

        case .saveButtonTapped:
            let itemIds = state.items.map({ $0.id })
            let tagIds = state.tags.map({ $0.id })
            switch dependency.clipCommandService.mergeClipItems(itemIds: itemIds, tagIds: tagIds, inClipsHaving: Array(state._sourceClipIds)) {
            case .success:
                dependency.clipMergeCompleted(true)
                nextState.isDismissed = true

            case .failure:
                nextState.alert = .error(L10n.clipMergeViewErrorAtMerge)
            }
            return (nextState, .none)

        case .cancelButtonTapped:
            dependency.clipMergeCompleted(false)
            nextState.isDismissed = true
            return (nextState, .none)

        // MARK: Button Action

        case .tagAdditionButtonTapped:
            let effect = showTagSelectionModal(selections: Set(state.tags.map({ $0.id })), dependency: dependency)
            return (state, [effect])

        case let .tagDeleteButtonTapped(tagId):
            nextState.tags = state.tags.filter({ $0.id != tagId })
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
            guard let tags = tags else { return (state, .none) }
            let sortedTags = Array(tags).sorted(by: { $0.name < $1.name })
            nextState.tags = sortedTags
            return (nextState, .none)

        // MARK: Alert Completion

        case .alertDismissed:
            nextState.alert = nil
            return (nextState, .none)

        // MARK: Transition

        case .didDismissedManually:
            dependency.clipMergeCompleted(false)
            nextState.isDismissed = true
            return (nextState, .none)
        }
    }
}

// MARK: - Preparation

extension ClipMergeViewReducer {
    static func prepareState(initialState: State, dependency: Dependency) -> State {
        let tags: [Tag]
        switch dependency.clipQueryService.readClipAndTags(for: Array(initialState._sourceClipIds)) {
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

// MARK: - Router

extension ClipMergeViewReducer {
    static func showTagSelectionModal(selections: Set<Tag.Identity>, dependency: HasRouter) -> Effect<Action> {
        let stream = Deferred {
            Future<Action?, Never> { promise in
                let isPresented = dependency.router.showTagSelectionModal(selections: selections) { tags in
                    promise(.success(.tagsSelected(tags)))
                }
                if !isPresented {
                    promise(.success(.tagsSelected(nil)))
                }
            }
        }
        return Effect(stream)
    }
}
