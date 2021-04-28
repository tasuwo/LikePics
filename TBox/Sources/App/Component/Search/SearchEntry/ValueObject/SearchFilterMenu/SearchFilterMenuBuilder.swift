//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

struct SearchFilterMenuBuilder: Equatable {
    typealias Action = SearchFilterMenuAction

    func build(_ setting: SearchFilterSetting,
               isSomeItemsHiddenByUserSetting: Bool,
               displaySettingChangeHandler: @escaping (DisplaySettingFilterMenuAction) -> Void,
               sortChangeHandler: @escaping (SortFilterMenuAction) -> Void) -> UIMenu
    {
        var menus: [UIMenu] = []

        if !isSomeItemsHiddenByUserSetting {
            let displaySettingActions: [DisplaySettingFilterMenuAction] = [
                .init(kind: .unspecified, isSelected: setting.isHidden == nil),
                .init(kind: .hidden, isSelected: setting.isHidden == true),
                .init(kind: .revealed, isSelected: setting.isHidden == false),
            ]
            let actions = displaySettingActions.map { action in action.uiAction { _ in displaySettingChangeHandler(action) } }
            menus.append(UIMenu(title: "", options: .displayInline, children: actions))
        }

        let sortActions: [SortFilterMenuAction] = [
            .init(kind: .createdDate, order: setting.sort.createdDateSort?.actionOrder),
            .init(kind: .updatedDate, order: setting.sort.updateDateOrder?.actionOrder),
            .init(kind: .dataSize, order: setting.sort.sizeOrder?.actionOrder),
        ]
        let actions = sortActions.map { action in action.uiAction { _ in sortChangeHandler(action) } }
        menus.append(UIMenu(title: "", options: .displayInline, children: actions))

        return UIMenu(title: "", children: menus)
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
