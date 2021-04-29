//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

struct SortFilterMenuAction: Equatable {
    enum Order: Equatable {
        case ascend
        case descend
    }

    enum Kind: Equatable {
        case createdDate
        case updatedDate
        case dataSize
    }

    let kind: Kind
    let order: Order?

    var title: String {
        switch kind {
        case .createdDate:
            return L10n.searchEntryMenuSortCreatedDate
        case .updatedDate:
            return L10n.searchEntryMenuSortUpdatedDate
        case .dataSize:
            return L10n.searchEntryMenuSortDataSize
        }
    }

    var isSelected: Bool { order != nil }

    var image: UIImage? {
        switch order {
        case .ascend:
            return UIImage(systemName: "chevron.up")
        case .descend:
            return UIImage(systemName: "chevron.down")
        case .none:
            return nil
        }
    }
}

extension SortFilterMenuAction: SearchFilterMenuAction {}
