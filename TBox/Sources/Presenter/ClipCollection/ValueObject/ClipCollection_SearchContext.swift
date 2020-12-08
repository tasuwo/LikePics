//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipCollection {
    enum SearchContext {
        enum Tag {
            case categorized(Domain.Tag)
            case uncategorized
        }

        case keywords([String])
        case tag(Tag)

        var label: String {
            switch self {
            case let .keywords(value):
                return value.joined(separator: ", ")

            case let .tag(.categorized(tag)):
                return tag.name

            case .tag(.uncategorized):
                return L10n.searchResultTitleUncategorized
            }
        }
    }
}
