//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct SearchEntryViewState: Equatable {
    enum Alert: Equatable {
        case removeAll
    }

    var searchHistories: [ClipSearchHistory]

    var alert: Alert?
}
