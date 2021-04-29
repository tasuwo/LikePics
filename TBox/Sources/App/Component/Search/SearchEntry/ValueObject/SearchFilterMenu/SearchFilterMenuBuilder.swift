//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

struct SearchFilterMenuBuilder: Equatable {
    typealias Action = SearchFilterMenuAction

    func build(_ setting: SearchFilterSetting,
               isSomeItemsHiddenByUserSetting: Bool,
               displaySettingChangeHandler: @escaping (Bool?) -> Void,
               sortChangeHandler: @escaping (ClipSearchSort) -> Void) -> UIMenu
    {
        var menus: [UIMenu] = []

        if !isSomeItemsHiddenByUserSetting {
            menus.append(Self.buildHiddenMenu(setting, changeHandler: displaySettingChangeHandler))
        }

        menus.append(Self.buildSortMenu(setting, changeHandler: sortChangeHandler))

        return UIMenu(title: "", children: menus)
    }

    private static func buildHiddenMenu(_ setting: SearchFilterSetting,
                                        changeHandler: @escaping (Bool?) -> Void) -> UIMenu
    {
        let actions: [DisplaySettingFilterMenuAction] = [
            .init(kind: .unspecified, isSelected: setting.isHidden == nil),
            .init(kind: .hidden, isSelected: setting.isHidden == true),
            .init(kind: .revealed, isSelected: setting.isHidden == false),
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

    private static func buildSortMenu(_ setting: SearchFilterSetting,
                                      changeHandler: @escaping (ClipSearchSort) -> Void) -> UIMenu
    {
        let actions: [SortFilterMenuAction] = [
            .init(kind: .createdDate, order: setting.sort.createdDateSort?.actionOrder),
            .init(kind: .updatedDate, order: setting.sort.updateDateOrder?.actionOrder),
            .init(kind: .dataSize, order: setting.sort.sizeOrder?.actionOrder),
        ]

        let uiActions = actions.map { action -> UIAction in
            let selectedSort: ClipSearchSort = {
                let order: ClipSearchSort.Order = {
                    guard let currentOrder = action.order?.searchOrder else { return .ascend }
                    switch currentOrder {
                    case .ascend:
                        return .descent
                    case .descent:
                        return .ascend
                    }
                }()

                switch action.kind {
                case .createdDate:
                    return .createdDate(order)
                case .updatedDate:
                    return .updatedDate(order)
                case .dataSize:
                    return .size(order)
                }
            }()

            return action.uiAction { _ in
                changeHandler(selectedSort)
            }
        }

        return UIMenu(title: "", options: .displayInline, children: uiActions)
    }
}

private extension SortFilterMenuAction.Order {
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
    var actionOrder: SortFilterMenuAction.Order {
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
        guard case let .createdDate(order) = self else { return nil }
        return order
    }

    var updateDateOrder: Order? {
        guard case let .updatedDate(order) = self else { return nil }
        return order
    }

    var sizeOrder: Order? {
        guard case let .size(order) = self else { return nil }
        return order
    }
}
