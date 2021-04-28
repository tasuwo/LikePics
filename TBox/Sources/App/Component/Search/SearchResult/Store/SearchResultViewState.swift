//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct SearchResultViewState: Equatable {
    struct SearchedTokenCandidates: Equatable {
        let searchQuery: ClipSearchQuery
        let tokenCandidates: [SearchToken]
    }

    struct SearchedClips: Equatable {
        let searchQuery: ClipSearchQuery
        let results: [Clip]
    }

    let searchEffectId = UUID()
    let searchCandidatesEffectId = UUID()

    var selectedSort: ClipSearchSort = .createdDate(.ascend)

    var inputtedText: String = ""
    var inputtedTokens: [SearchToken] = []

    var searchedTokenCandidates: SearchedTokenCandidates? = nil
    var searchedClips: SearchedClips? = nil

    var isSearchingTokenCandidates: Bool = false
    var isSearchingClips: Bool = false

    var isSomeItemsHidden: Bool = false
}

extension SearchResultViewState {
    var tokenCandidates: [SearchToken] { searchedTokenCandidates?.tokenCandidates ?? [] }
    var searchResults: [Clip] { searchedClips?.results ?? [] }

    var searchQuery: ClipSearchQuery {
        let albumIds = inputtedTokens
            .filter { $0.kind == .album }
            .map { $0.id }
        let tagIds = inputtedTokens
            .filter { $0.kind == .tag }
            .map { $0.id }
        let includesHiddenItems = !isSomeItemsHidden

        return .init(text: inputtedText,
                     albumIds: albumIds,
                     tagIds: tagIds,
                     sort: selectedSort,
                     isHidden: includesHiddenItems ? nil : false)
    }

    var searchQueryTitle: String {
        var queries = inputtedTokens.map { $0.title }
        if !inputtedText.isEmpty { queries.append(inputtedText) }
        return ListFormatter.localizedString(byJoining: queries)
    }
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
        return L10n.searchResultNotFoundMessage(searchQueryTitle)
    }
}
