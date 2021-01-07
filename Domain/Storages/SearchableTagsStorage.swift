//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct SearchableTagsStorage {
    struct History {
        let lastComparableFilterQuery: String
        let tags: [Tag]
    }

    private var lastResult: History?

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Methods

    public mutating func perform(query: String, to tags: [Tag]) -> [Tag] {
        let comparableFilterQuery = Tag.transformToSearchableText(text: query) ?? ""
        if let lastResult = lastResult, comparableFilterQuery == lastResult.lastComparableFilterQuery {
            return lastResult.tags
        } else {
            return self.perform(comparableFilterQuery: comparableFilterQuery, to: tags)
        }
    }

    private mutating func perform(comparableFilterQuery: String, to tags: [Tag]) -> [Tag] {
        if comparableFilterQuery.isEmpty {
            self.lastResult = nil
            return tags
        }

        let filteredTags = tags
            .filter {
                guard let name = $0.searchableName else { return false }
                return name.contains(comparableFilterQuery)
            }

        self.lastResult = .init(lastComparableFilterQuery: comparableFilterQuery,
                                tags: filteredTags)

        return filteredTags
    }
}
