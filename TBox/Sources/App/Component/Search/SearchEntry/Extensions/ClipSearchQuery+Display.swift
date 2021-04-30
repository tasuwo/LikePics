//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipSearchQuery {
    var displayTitle: String {
        var queries = tokens.map { $0.title }
        if !text.isEmpty { queries.append(text) }
        return ListFormatter.localizedString(byJoining: queries)
    }
}
