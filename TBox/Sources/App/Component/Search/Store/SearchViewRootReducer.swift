//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import ForestKit

typealias SearchViewRootDependency = SearchEntryViewDependency
    & SearchResultViewDependency

private typealias RootState = SearchViewRootState
private typealias RootAction = SearchViewRootAction

let searchViewRootReducer = MergeReducer<SearchViewRootState, SearchViewRootAction, SearchViewRootDependency>(
    SearchEntryViewReducer().upstream(RootState.entryConverter,
                                      RootAction.entryConverter,
                                      { $0 as SearchEntryViewDependency }),
    SearchResultViewReducer().upstream(RootState.resultConverter,
                                       RootAction.resultConverter,
                                       { $0 as SearchResultViewDependency })
)
