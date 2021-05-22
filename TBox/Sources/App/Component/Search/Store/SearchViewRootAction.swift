//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ForestKit

enum SearchViewRootAction: Action {
    case entry(SearchEntryViewAction)
    case result(SearchResultViewAction)
}

extension SearchViewRootAction {
    static let entryConverter: ActionConverter<Self, SearchEntryViewAction> = .init {
        guard case let .entry(action) = $0 else { return nil }; return action
    } convert: {
        .entry($0)
    }

    static let resultConverter: ActionConverter<Self, SearchResultViewAction> = .init {
        guard case let .result(action) = $0 else { return nil }; return action
    } convert: {
        .result($0)
    }
}
