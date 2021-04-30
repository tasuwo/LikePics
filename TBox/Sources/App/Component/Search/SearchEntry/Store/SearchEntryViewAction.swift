//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum SearchEntryViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case searchHistoriesChanged([ClipSearchHistory])

    // MARK: Search History

    case selectedHistory(ClipSearchHistory)
    case removedHistory(ClipSearchHistory, completion: (Bool) -> Void)
    case removeAllHistories

    // MARK: Alert Completion

    case alertDeleteConfirmed
}
