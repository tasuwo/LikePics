//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit

struct SearchViewRootState: Equatable {
    var entryState: SearchEntryViewState
    var resultState: SearchResultViewState
}

extension SearchViewRootState {
    var shouldShowResultsView: Bool {
        resultState.inputtedText.isEmpty == false || resultState.inputtedTokens.isEmpty == false
    }
}

extension SearchViewRootState {
    init(isSomeItemsHidden: Bool) {
        entryState = .init(isSomeItemsHidden: isSomeItemsHidden)
        resultState = .init(isSomeItemsHidden: isSomeItemsHidden)
    }
}

extension SearchViewRootState {
    static let entryMapping: StateMapping<Self, SearchEntryViewState> = .init(keyPath: \.entryState)
    static let resultMapping: StateMapping<Self, SearchResultViewState> = .init(keyPath: \.resultState)
}

extension SearchViewRootState {
    func removingSessionStates() -> Self {
        var state = self
        state.entryState.searchHistories = []
        state.entryState.alert = nil
        state.resultState.searchedTokenCandidates = nil
        state.resultState.searchedClips = nil
        return state
    }
}

// MARK: - Codable

extension SearchViewRootState: Codable {}
