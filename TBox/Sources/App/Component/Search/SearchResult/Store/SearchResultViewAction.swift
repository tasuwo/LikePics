//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum SearchResultViewAction: Action {
    // MARK: State Observation

    case searchQueryChanged(SearchQuery)

    // MARK: - Selection

    case selectedTokenCandidate(SearchToken)
    case selectedResult(Clip)
    case selectedSeeAllResultsButton

    // MARK: - Search Execution

    case foundResults([Clip], byQuery: SearchQuery)
    case foundCandidates([SearchToken], byText: String)
}
