//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct SearchableStorage<Item: Searchable & Codable>: Equatable, Codable {
    struct History: Equatable, Codable {
        let lastComparableFilterQuery: String
        let items: [Item]
    }

    private var cache = Set<Item.Identity>()
    private var lastResult: History?

    // MARK: - Lifecycle

    public init() {}

    // MARK: - Methods

    public mutating func perform(query: String, to items: [Item]) -> [Item] {
        let itemByIds = items.reduce(into: [Item.Identity: Item]()) { $0[$1.identity] = $1 }
        let ids = Set(itemByIds.keys)

        defer {
            cache = ids
        }

        let comparableFilterQuery = query.transformToSearchableText() ?? ""
        if cache != ids {
            return self.perform(comparableFilterQuery: comparableFilterQuery, to: items)
        } else if let lastResult = lastResult, comparableFilterQuery == lastResult.lastComparableFilterQuery {
            let appliedItems = Self.apply(itemByIds, to: lastResult.items)
            self.lastResult = .init(
                lastComparableFilterQuery: comparableFilterQuery,
                items: appliedItems
            )
            return appliedItems
        } else {
            return self.perform(comparableFilterQuery: comparableFilterQuery, to: items)
        }
    }

    // MARK: Privates

    private mutating func perform(comparableFilterQuery: String, to items: [Item]) -> [Item] {
        if comparableFilterQuery.isEmpty {
            self.lastResult = nil
            return items
        }

        let filteredItems =
            items
            .filter {
                guard let text = $0.searchableText else { return false }
                return text.contains(comparableFilterQuery)
            }

        self.lastResult = .init(
            lastComparableFilterQuery: comparableFilterQuery,
            items: filteredItems
        )

        return filteredItems
    }

    private static func apply(_ itemsByIds: [Item.Identity: Item], to items: [Item]) -> [Item] {
        return
            items
            .map { $0.identity }
            .compactMap { itemsByIds[$0] }
    }
}
