//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct SearchableTagsStorage {
    struct SearchableTag: Equatable, Hashable {
        let tag: Tag
        let comparableName: String?

        init(tag: Tag) {
            self.tag = tag
            self.comparableName = Self.transformToSearchableText(text: tag.name)
        }

        static func transformToSearchableText(text: String) -> String? {
            return text
                .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
                .applyingTransform(.hiraganaToKatakana, reverse: false)?
                .lowercased()
        }
    }

    struct History {
        let lastComparableFilterQuery: String
        let tags: [Tag]
    }

    private var cache: [Tag] = []
    private var lastResult: History?

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Methods

    public mutating func perform(query: String, to tags: [Tag]) -> [Tag] {
        defer {
            self.cache = tags
        }

        let comparableFilterQuery = SearchableTag.transformToSearchableText(text: query) ?? ""
        if self.cache != tags {
            return self.perform(comparableFilterQuery: comparableFilterQuery, to: tags)
        } else if let lastResult = lastResult, comparableFilterQuery == lastResult.lastComparableFilterQuery {
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
            .map { SearchableTag(tag: $0) }
            .filter {
                guard let name = $0.comparableName else { return false }
                return name.contains(comparableFilterQuery)
            }
            .map { $0.tag }

        self.lastResult = .init(lastComparableFilterQuery: comparableFilterQuery,
                                tags: filteredTags)

        return filteredTags
    }
}
