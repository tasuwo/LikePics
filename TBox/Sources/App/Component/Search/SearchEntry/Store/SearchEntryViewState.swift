//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct SearchEntryViewState: Equatable {
    enum Alert: Equatable {
        case removeAll
    }

    var searchHistories: [ClipSearchHistory]
    var isSomeItemsHidden: Bool

    var alert: Alert?
}

extension SearchEntryViewState {
    init(isSomeItemsHidden: Bool) {
        searchHistories = []
        self.isSomeItemsHidden = isSomeItemsHidden

        alert = nil
    }
}
