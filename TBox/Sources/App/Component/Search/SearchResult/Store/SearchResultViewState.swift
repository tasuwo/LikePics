//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct SearchResultViewState: Equatable {
    struct SearchedTokenCandidates: Equatable {
        let searchText: String
        let tokenCandidates: [SearchToken]
    }

    struct SearchedClips: Equatable {
        let searchQuery: SearchQuery
        let results: [Clip]
    }

    let searchEffectId = UUID()
    let searchCandidatesEffectId = UUID()

    var searchQuery: SearchQuery

    var searchedTokenCandidates: SearchedTokenCandidates? = nil
    var searchedClips: SearchedClips? = nil

    var isSearchingTokenCandidates: Bool = false
    var isSearchingClips: Bool = false
}

extension SearchResultViewState {
    var tokenCandidates: [SearchToken] { searchedTokenCandidates?.tokenCandidates ?? [] }
    var searchResults: [Clip] { searchedClips?.results ?? [] }
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
