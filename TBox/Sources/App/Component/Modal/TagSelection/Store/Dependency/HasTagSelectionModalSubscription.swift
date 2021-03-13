//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

protocol HasTagSelectionModalSubscription {
    var tagSelectionCompleted: (Set<Tag>?) -> Void { get }
}
