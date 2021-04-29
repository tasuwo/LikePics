//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct SearchResultViewState: Equatable {
    struct SearchedTokenCandidates: Equatable {
        let searchText: String
        let includesHiddenItems: Bool
        let tokenCandidates: [ClipSearchToken]
    }

    struct SearchedClips: Equatable {
        let searchQuery: ClipSearchQuery
        let results: [Clip]
    }

    let searchEffectId = UUID()
    let searchCandidatesEffectId = UUID()

    var searchOnlyHiddenItems: Bool? = nil
    var selectedSort: ClipSearchSort = .createdDate(.descent)

    var inputtedText: String = ""
    var inputtedTokens: [ClipSearchToken] = []

    var searchedTokenCandidates: SearchedTokenCandidates? = nil
    var searchedClips: SearchedClips? = nil

    var isSearchingTokenCandidates: Bool = false
    var isSearchingClips: Bool = false

    var isSomeItemsHidden: Bool
}

extension SearchResultViewState {
    var tokenCandidates: [ClipSearchToken] { searchedTokenCandidates?.tokenCandidates ?? [] }
    var searchResults: [Clip] { searchedClips?.results ?? [] }
    var isSearching: Bool { isSearchingTokenCandidates || isSearchingClips }
    var isResultsEmpty: Bool { searchResults.isEmpty && tokenCandidates.isEmpty }

    var searchQuery: ClipSearchQuery {
        let albumIds = inputtedTokens
            .filter { $0.kind == .album }
            .map { $0.id }
        let tagIds = inputtedTokens
            .filter { $0.kind == .tag }
            .map { $0.id }
        return .init(text: inputtedText,
                     albumIds: albumIds,
                     tagIds: tagIds,
                     sort: filterSetting.sort,
                     isHidden: isSomeItemsHidden ? false : searchOnlyHiddenItems)
    }

    var searchQueryTitle: String {
        var queries = inputtedTokens.map { $0.title }
        if !inputtedText.isEmpty { queries.append(inputtedText) }
        return ListFormatter.localizedString(byJoining: queries)
    }

    var filterSetting: ClipSearchFilterSetting {
        return .init(isHidden: searchOnlyHiddenItems,
                     sort: selectedSort)
    }
}

extension SearchResultViewState {
    var isNotFoundMessageDisplaying: Bool {
        !searchQuery.isEmpty && !isSearching && isResultsEmpty
    }

    var notFoundMessage: String {
        return L10n.searchResultNotFoundMessage(searchQueryTitle)
    }
}
