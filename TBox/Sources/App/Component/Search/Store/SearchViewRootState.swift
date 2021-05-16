//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

struct SearchViewRootState: Equatable {
    var entryState: SearchEntryViewState
    var resultState: SearchResultViewState
}

extension SearchViewRootState {
    init(isSomeItemsHidden: Bool) {
        entryState = .init(isSomeItemsHidden: isSomeItemsHidden)
        resultState = .init(isSomeItemsHidden: isSomeItemsHidden)
    }
}

extension SearchViewRootState {
    static let entryConverter: StateConverter<Self, SearchEntryViewState> = .init {
        $0.entryState
    } merge: { state, parent in
        var nextParent = parent
        nextParent.entryState = state
        return nextParent
    }

    static let resultConverter: StateConverter<Self, SearchResultViewState> = .init {
        $0.resultState
    } merge: { state, parent in
        var nextParent = parent
        nextParent.resultState = state
        return nextParent
    }
}

// MARK: - Codable

extension SearchViewRootState: Codable {}
