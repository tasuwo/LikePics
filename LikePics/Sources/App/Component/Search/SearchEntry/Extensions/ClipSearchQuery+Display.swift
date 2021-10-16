//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import Foundation

extension ClipSearchQuery {
    var displayTitle: String {
        var queries = tokens.map { $0.title }
        if !text.isEmpty { queries.append(text) }
        return ListFormatter.localizedString(byJoining: queries)
    }

    var displaySettingDisplayTitle: String {
        switch isHidden {
        case .some(true):
            return L10n.searchEntryMenuDisplaySettingHidden

        case .some(false):
            return L10n.searchEntryMenuDisplaySettingRevealed

        case .none:
            return L10n.searchEntryMenuDisplaySettingUnspecified
        }
    }
}

extension ClipSearchSort {
    var displayTitle: String {
        let kindString: String = {
            switch kind {
            case .createdDate:
                return L10n.searchEntryMenuSortCreatedDate

            case .updatedDate:
                return L10n.searchEntryMenuSortUpdatedDate

            case .size:
                return L10n.searchEntryMenuSortDataSize
            }
        }()

        let orderString: String = {
            switch order {
            case .ascend:
                return L10n.searchEntryMenuSortAsc

            case .descent:
                return L10n.searchEntryMenuSortDesc
            }
        }()

        return ListFormatter.localizedString(byJoining: [kindString, orderString])
    }
}
