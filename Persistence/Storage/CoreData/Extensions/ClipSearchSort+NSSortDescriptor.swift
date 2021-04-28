//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipSearchSort {
    var sortDescriptor: NSSortDescriptor {
        switch self {
        case let .createdDate(order):
            return NSSortDescriptor(keyPath: \Clip.createdDate, ascending: order.isAscending)
        case let .updatedDate(order):
            return NSSortDescriptor(keyPath: \Clip.updatedDate, ascending: order.isAscending)
        case let .size(order):
            return NSSortDescriptor(keyPath: \Clip.imagesSize, ascending: order.isAscending)
        }
    }
}
