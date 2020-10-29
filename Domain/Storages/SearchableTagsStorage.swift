//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct SearchableTagsStorage {
    typealias SearchableTag = (tag: Tag, comparableName: String)

    struct History {
        let comparableFilterQuery: String
        let tags: [Tag]
    }

    private var cache: LazySequence<[SearchableTag]> = [SearchableTag]().lazy
    private var lastResult: History?

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Methods

    private static func transformToSearchableText(text: String) -> String? {
        return text
            .applyingTransform(.fullwidthToHalfwidth, reverse: false)?
            .applyingTransform(.hiraganaToKatakana, reverse: false)?
            .lowercased()
    }

    public mutating func updateCache(_ tags: [Tag]) {
        self.cache = tags.map { (tag: $0, comparableName: Self.transformToSearchableText(text: $0.name) ?? $0.name) }.lazy
    }

    public mutating func resolveTags(byQuery query: String) -> [Tag] {
        guard !query.isEmpty else {
            self.lastResult = nil
            return Array(self.cache.map({ $0.tag }))
        }

        let comparableFilterQuery = Self.transformToSearchableText(text: query) ?? query
        if let lastResult = lastResult, comparableFilterQuery == lastResult.comparableFilterQuery {
            return lastResult.tags
        }

        return self.cache
            .filter { $0.comparableName.contains(comparableFilterQuery) }
            .map { $0.tag }
    }
}
