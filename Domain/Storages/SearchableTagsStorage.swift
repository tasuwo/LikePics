//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct SearchableTagsStorage {
    struct History {
        let lastComparableFilterQuery: String
        let tags: [Tag]
    }

    private var cache = Set<Tag.Identity>()
    private var lastResult: History?

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Methods

    public mutating func perform(query: String, to tags: [Tag]) -> [Tag] {
        let tagByIds = tags.reduce(into: [Tag.Identity: Tag]()) { $0[$1.id] = $1 }
        let ids = Set(tagByIds.keys)

        defer {
            cache = ids
        }

        let comparableFilterQuery = Tag.transformToSearchableText(text: query) ?? ""
        if cache != ids {
            return self.perform(comparableFilterQuery: comparableFilterQuery, to: tags)
        } else if let lastResult = lastResult, comparableFilterQuery == lastResult.lastComparableFilterQuery {
            let appliedTags = lastResult.tags.applying(tagByIds)
            self.lastResult = .init(lastComparableFilterQuery: comparableFilterQuery,
                                    tags: appliedTags)
            return appliedTags
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

extension Array where Element == Tag {
    func applying(_ tagByIds: [Tag.Identity: Tag]) -> Self {
        return self
            .map { $0.id }
            .compactMap { tagByIds[$0] }
    }
}
