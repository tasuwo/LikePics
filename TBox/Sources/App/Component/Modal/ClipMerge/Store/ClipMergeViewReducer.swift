//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

typealias ClipMergeViewDependency = HasRouter
    & HasClipQueryService
    & HasClipCommandService
    & HasModalNotificationCenter

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
            switch dependency.clipCommandService.mergeClipItems(itemIds: itemIds, tagIds: tagIds, inClipsHaving: Array(state.sourceClipIds)) {
            case .success:
                dependency.modalNotificationCenter.post(id: state.id,
                                                        name: .clipMergeModal,
                                                        userInfo: [.clipMergeCompleted: true])
                nextState.isDismissed = true

            case .failure:
                nextState.alert = .error(L10n.clipMergeViewErrorAtMerge)
            }
            return (nextState, .none)

        case .cancelButtonTapped:
            dependency.modalNotificationCenter.post(id: state.id,
                                                    name: .clipMergeModal,
                                                    userInfo: [.clipMergeCompleted: false])
            nextState.isDismissed = true
            return (nextState, .none)

        // MARK: Button Action

        case .tagAdditionButtonTapped:
            nextState.modal = .tagSelection(tagIds: Set(state.tags.map({ $0.id })))
            return (nextState, .none)

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
            dependency.modalNotificationCenter.post(id: state.id,
                                                    name: .clipMergeModal,
                                                    userInfo: [.clipMergeCompleted: false])
            nextState.isDismissed = true
            return (nextState, .none)
        }
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

// MARK: - ModalNotification

extension ModalNotification.Name {
    static let clipMergeModal = ModalNotification.Name("net.tasuwo.TBox.ClipMergeViewReducer.clipMergeModal")
}

extension ModalNotification.UserInfoKey {
    static let clipMergeCompleted = ModalNotification.UserInfoKey(rawValue: "net.tasuwo.TBox.ClipMergeViewReducer.clipMergeCompleted")
}
