//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct SearchResultViewState: Equatable {
    var searchQuery: SearchQuery

    var tokenCandidates: [SearchToken]
    var searchResults: [Clip]
}
