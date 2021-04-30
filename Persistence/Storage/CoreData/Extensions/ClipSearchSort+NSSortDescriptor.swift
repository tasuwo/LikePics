//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipSearchSort {
    var sortDescriptor: NSSortDescriptor {
        switch kind {
        case .createdDate:
            return NSSortDescriptor(keyPath: \Clip.createdDate, ascending: order.isAscending)

        case .updatedDate:
            return NSSortDescriptor(keyPath: \Clip.updatedDate, ascending: order.isAscending)

        case .size:
            return NSSortDescriptor(keyPath: \Clip.imagesSize, ascending: order.isAscending)
        }
    }
}
