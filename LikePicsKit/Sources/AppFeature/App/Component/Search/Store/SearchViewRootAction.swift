//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit

enum SearchViewRootAction: Action {
    case entry(SearchEntryViewAction)
    case result(SearchResultViewAction)
}

extension SearchViewRootAction {
    static let entryMapping: ActionMapping<Self, SearchEntryViewAction> = .init(build: {
        .entry($0)
    }, get: {
        guard case let .entry(action) = $0 else { return nil }; return action
    })

    static let resultMapping: ActionMapping<Self, SearchResultViewAction> = .init(build: {
        .result($0)
    }, get: {
        guard case let .result(action) = $0 else { return nil }; return action
    })
}
