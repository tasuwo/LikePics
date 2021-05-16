//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
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

    let searchEffectId: UUID
    let searchCandidatesEffectId: UUID

    var searchOnlyHiddenItems: Bool?
    var selectedSort: ClipSearchSort

    var inputtedText: String
    var inputtedTokens: [ClipSearchToken]

    var searchedTokenCandidates: SearchedTokenCandidates?
    var searchedClips: SearchedClips?

    var previewingClipId: Clip.Identity?

    var isSearchingTokenCandidates: Bool
    var isSearchingClips: Bool

    var isSomeItemsHidden: Bool
}

extension SearchResultViewState {
    init(isSomeItemsHidden: Bool) {
        searchEffectId = UUID()
        searchCandidatesEffectId = UUID()

        searchOnlyHiddenItems = nil
        selectedSort = .init(kind: .createdDate, order: .descent)

        inputtedText = ""
        inputtedTokens = []

        searchedTokenCandidates = nil
        searchedClips = nil

        previewingClipId = nil

        isSearchingTokenCandidates = false
        isSearchingClips = false

        self.isSomeItemsHidden = isSomeItemsHidden
    }
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

    var notFoundMessageViewAlpha: CGFloat {
        isNotFoundMessageDisplaying ? 1 : 0
    }

    var notFoundMessage: String? {
        return L10n.searchResultNotFoundMessage(searchQuery.displayTitle)
    }
}

// MARK: - Codable

extension SearchResultViewState: Codable {}

extension SearchResultViewState.SearchedTokenCandidates: Codable {}

extension SearchResultViewState.SearchedClips: Codable {}
