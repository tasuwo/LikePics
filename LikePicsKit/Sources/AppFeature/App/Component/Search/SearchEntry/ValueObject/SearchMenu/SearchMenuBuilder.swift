//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

struct SearchMenuBuilder: Equatable {
    typealias Action = SearchMenuAction

    func build(_ state: SearchMenuState,
               isSomeItemsHiddenByUserSetting: Bool,
               displaySettingChangeHandler: @escaping (Bool?) -> Void,
               sortChangeHandler: @escaping (ClipSearchSort) -> Void) -> UIMenu
    {
        var menus: [UIMenu] = []

        if !isSomeItemsHiddenByUserSetting {
            menus.append(Self.buildHiddenMenu(state, changeHandler: displaySettingChangeHandler))
        }

        menus.append(Self.buildSortMenu(state, changeHandler: sortChangeHandler))

        return UIMenu(title: "", children: menus)
    }

    private static func buildHiddenMenu(_ state: SearchMenuState,
                                        changeHandler: @escaping (Bool?) -> Void) -> UIMenu
    {
        let actions: [SearchMenuDisplaySettingAction] = [
            .init(kind: .unspecified, isSelected: state.shouldSearchOnlyHiddenClip == nil),
            .init(kind: .hidden, isSelected: state.shouldSearchOnlyHiddenClip == true),
            .init(kind: .revealed, isSelected: state.shouldSearchOnlyHiddenClip == false)
        ]

        let uiActions = actions.map { action -> UIAction in
            let searchOnlyHiddenItems: Bool? = {
                switch action.kind {
                case .unspecified:
                    return nil

                case .hidden:
                    return true

                case .revealed:
                    return false
                }
            }()

            return action.uiAction { _ in
                changeHandler(searchOnlyHiddenItems)
            }
        }

        return UIMenu(title: "", options: .displayInline, children: uiActions)
    }

    private static func buildSortMenu(_ state: SearchMenuState,
                                      changeHandler: @escaping (ClipSearchSort) -> Void) -> UIMenu
    {
        let actions: [SearchMenuSortAction] = [
            .init(kind: .createdDate, order: state.sort.createdDateSort?.actionOrder),
            .init(kind: .updatedDate, order: state.sort.updateDateOrder?.actionOrder),
            .init(kind: .dataSize, order: state.sort.sizeOrder?.actionOrder)
        ]

        let uiActions = actions.map { action -> UIAction in
            let selectedSort: ClipSearchSort = {
                let order: ClipSearchSort.Order = {
                    guard let currentOrder = action.order?.searchOrder else { return .descent }
                    switch currentOrder {
                    case .ascend:
                        return .descent

                    case .descent:
                        return .ascend
                    }
                }()

                switch action.kind {
                case .createdDate:
                    return .init(kind: .createdDate, order: order)

                case .updatedDate:
                    return .init(kind: .updatedDate, order: order)

                case .dataSize:
                    return .init(kind: .size, order: order)
                }
            }()

            return action.uiAction { _ in
                changeHandler(selectedSort)
            }
        }

        return UIMenu(title: "", options: .displayInline, children: uiActions)
    }
}

private extension SearchMenuSortAction.Order {
    var searchOrder: ClipSearchSort.Order {
        switch self {
        case .ascend:
            return .ascend

        case .descend:
            return .descent
        }
    }
}

private extension ClipSearchSort.Order {
    var actionOrder: SearchMenuSortAction.Order {
        switch self {
        case .ascend:
            return .ascend

        case .descent:
            return .descend
        }
    }
}

private extension ClipSearchSort {
    var createdDateSort: Order? {
        guard case .createdDate = kind else { return nil }
        return order
    }

    var updateDateOrder: Order? {
        guard case .updatedDate = kind else { return nil }
        return order
    }

    var sizeOrder: Order? {
        guard case .size = kind else { return nil }
        return order
    }
}
