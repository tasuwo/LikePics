//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct SearchResultViewState: Equatable {
    let searchEffectId = UUID()
    let searchCandidatesEffectId = UUID()

    var searchQuery: SearchQuery

    var tokenCandidates: [SearchToken]
    var searchResults: [Clip]

    var isSearchingTokenCandidates: Bool = false
    var isSearchingClips: Bool = false
}

extension SearchResultViewState {
    var isNotFoundMessageDisplaying: Bool {
        !searchQuery.isEmpty
            && !isSearchingTokenCandidates
            && !isSearchingClips
            && searchResults.isEmpty
            && tokenCandidates.isEmpty
    }

    var notFoundMessage: String {
        return L10n.searchResultNotFoundMessage(ListFormatter.localizedString(byJoining: searchQuery.queryNames))
    }
}
