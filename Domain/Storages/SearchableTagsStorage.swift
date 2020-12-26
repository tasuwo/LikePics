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

    private var comparableCache: [Tag] = []
    private var cache: LazySequence<[SearchableTag]> = [SearchableTag]().lazy
    private var lastResult: History?

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Methods

    public mutating func updateCache(_ tags: [Tag]) {
        guard self.comparableCache != tags else { return }
        self.cache = tags.map { SearchableTag(tag: $0) }.lazy
        self.comparableCache = tags
    }

    public mutating func resolveTags(byQuery query: String) -> [Tag] {
        if query.isEmpty {
            self.lastResult = nil
            return Array(self.cache.map({ $0.tag }))
        }

        let comparableFilterQuery = SearchableTag.transformToSearchableText(text: query) ?? query
        if let lastResult = lastResult, comparableFilterQuery == lastResult.lastComparableFilterQuery {
            return lastResult.tags
        }

        let tags: [Tag] = self.cache
            .filter {
                guard let name = $0.comparableName else { return false }
                return name.contains(comparableFilterQuery)
            }
            .map { $0.tag }

        self.lastResult = .init(lastComparableFilterQuery: comparableFilterQuery,
                                tags: tags)

        return tags
    }
}
