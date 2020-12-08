//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

extension ClipCollection {
    enum SearchContext {
        enum Tag {
            case named(String)
            case uncategorized
        }

        case keywords([String])
        case tag(Tag)

        var label: String {
            switch self {
            case let .keywords(value):
                return value.joined(separator: ", ")

            case let .tag(.named(name)):
                return name

            case .tag(.uncategorized):
                return L10n.searchResultTitleUncategorized
            }
        }
    }
}
