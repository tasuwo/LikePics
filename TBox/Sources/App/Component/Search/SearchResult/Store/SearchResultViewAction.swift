//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum SearchResultViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad
    case entryViewDidAppear

    // MARK: State Observation

    case searchBarChanged(text: String, tokens: [ClipSearchToken])
    case settingUpdated(isSomeItemsHidden: Bool)

    // MARK: - Menu

    case displaySettingMenuChanged(Bool?)
    case sortMenuChanged(ClipSearchSort)

    // MARK: - Selection

    case selectedHistory(ClipSearchHistory)
    case selectedTokenCandidate(ClipSearchToken)
    case selectedResult(Clip)
    case selectedSeeAllResultsButton

    // MARK: - Search Execution

    case foundResults([Clip], byQuery: ClipSearchQuery)
    case foundCandidates([ClipSearchToken], byText: String, includesHiddenItems: Bool)
}
