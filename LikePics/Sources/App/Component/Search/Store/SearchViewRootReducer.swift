//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CompositeKit

typealias SearchViewRootDependency = SearchEntryViewDependency
    & SearchResultViewDependency

private typealias RootState = SearchViewRootState
private typealias RootAction = SearchViewRootAction

let searchViewRootReducer = combine(
    contramap(RootAction.entryMapping, RootState.entryMapping, { $0 as SearchViewRootDependency })(SearchEntryViewReducer()),
    contramap(RootAction.resultMapping, RootState.resultMapping, { $0 })(SearchResultViewReducer())
)
