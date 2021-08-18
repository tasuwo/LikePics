//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ForestKit

enum ClipItemListRootAction: Action {
    case list(ClipItemListAction)
    case toolBar(ClipItemListToolBarAction)
    case navigationBar(ClipItemListNavigationBarAction)
}

extension ClipItemListRootAction {
    static let mappingToList: ActionMapping<Self, ClipItemListAction> = .init(build: {
        .list($0)
    }, get: {
        switch $0 {
        case let .list(action):
            return action

        case let .navigationBar(action):
            guard let event = action.mapToEvent() else { return nil }
            return .navigationBarEventOccurred(event)

        case let .toolBar(action):
            guard let event = action.mapToEvent() else { return nil }
            return .toolBarEventOccurred(event)
        }
    })

    static let mappingToToolBar: ActionMapping<Self, ClipItemListToolBarAction> = .init(build: {
        .toolBar($0)
    }, get: {
        guard case let .toolBar(action) = $0 else { return nil }; return action
    })

    static let mappingToNavigationBar: ActionMapping<Self, ClipItemListNavigationBarAction> = .init(build: {
        .navigationBar($0)
    }, get: {
        guard case let .navigationBar(action) = $0 else { return nil }; return action
    })
}

private extension ClipItemListToolBarAction {
    func mapToEvent() -> ClipItemListToolBarEvent? {
        switch self {
        case .editUrlButtonTapped:
            return .editUrl

        case let .alertShareConfirmed(succeeded):
            return .share(succeeded)

        case .alertDeleteConfirmed:
            return .delete

        default:
            return nil
        }
    }
}

private extension ClipItemListNavigationBarAction {
    func mapToEvent() -> ClipItemListNavigationBarEvent? {
        switch self {
        case .didTapResume:
            return .resume

        case .didTapCancel:
            return .cancel

        case .didTapSelect:
            return .select

        default:
            return nil
        }
    }
}
