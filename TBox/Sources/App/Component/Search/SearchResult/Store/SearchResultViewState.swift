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
    var selectedSort: ClipSearchSort = .init(kind: .createdDate, order: .descent)

    var inputtedText: String = ""
    var inputtedTokens: [ClipSearchToken] = []

    var searchedTokenCandidates: SearchedTokenCandidates? = nil
    var searchedClips: SearchedClips? = nil

    var previewingClipId: Clip.Identity? = nil

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
        return .init(text: inputtedText,
                     tokens: inputtedTokens,
                     isHidden: isSomeItemsHidden ? false : searchOnlyHiddenItems,
                     sort: selectedSort)
    }

    var searchQueryTitle: String {
        var queries = inputtedTokens.map { $0.title }
        if !inputtedText.isEmpty { queries.append(inputtedText) }
        return ListFormatter.localizedString(byJoining: queries)
    }

    var menuState: SearchMenuState {
        return .init(shouldSearchOnlyHiddenClip: searchOnlyHiddenItems,
                     sort: selectedSort)
    }

    var previewingClip: Clip? {
        guard let clipId = previewingClipId else { return nil }
        return searchedClips?.results.first(where: { $0.id == clipId })
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
