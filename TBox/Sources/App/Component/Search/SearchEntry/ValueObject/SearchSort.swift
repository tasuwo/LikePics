//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

struct SearchSort: Equatable, Hashable {
    enum Kind {
        case createdDate
        case dataSize
        case url
    }

    enum Order {
        case descend
        case ascend
    }

    let kind: Kind
    let order: Order
}

extension SearchSort.Order {
    var icon: UIImage {
        switch self {
        case .ascend:
            // swiftlint:disable:next force_unwrapping
            return UIImage(systemName: "chevron.down")!

        case .descend:
            // swiftlint:disable:next force_unwrapping
            return UIImage(systemName: "chevron.up")!
        }
    }
}
