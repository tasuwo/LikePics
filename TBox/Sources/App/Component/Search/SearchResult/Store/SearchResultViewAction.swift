//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum SearchResultViewAction: Action {
    // MARK: View Life-Cycle

    case viewDidLoad

    // MARK: State Observation

    case searchBarChanged(text: String, tokens: [SearchToken])
    case settingUpdated(isSomeItemsHidden: Bool)

    // MARK: - Menu

    case displaySettingMenuChanged(DisplaySettingFilterMenuAction)
    case sortMenuChanged(SortFilterMenuAction)

    // MARK: - Selection

    case selectedTokenCandidate(SearchToken)
    case selectedResult(Clip)
    case selectedSeeAllResultsButton

    // MARK: - Search Execution

    case foundResults([Clip], byQuery: ClipSearchQuery)
    case foundCandidates([SearchToken], byText: String, includesHiddenItems: Bool)
}
