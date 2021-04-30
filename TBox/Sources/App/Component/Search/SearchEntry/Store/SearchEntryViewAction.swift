//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum SearchEntryViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case searchHistoriesChanged([ClipSearchHistory])
    case settingUpdated(isSomeItemsHidden: Bool)

    // MARK: Search History

    case removedHistory(ClipSearchHistory, completion: (Bool) -> Void)
    case removeAllHistories

    // MARK: Alert Completion

    case alertDeleteConfirmed
}
