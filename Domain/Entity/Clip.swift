//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

// sourcery: AutoDefaultValue
public struct Clip: Equatable {
    public let url: URL
    public let description: String?
    /// - attention: Sorted by clipIndex.
    public let items: [ClipItem]
    public let tags: [String]
    public let isHidden: Bool
    public let registeredDate: Date
    public let updatedDate: Date

    public var primaryItem: ClipItem? {
        guard self.items.indices.contains(0) else { return nil }
        return self.items[0]
    }

    public var secondaryItem: ClipItem? {
        guard self.items.indices.contains(1) else { return nil }
        return self.items[1]
    }

    public var tertiaryItem: ClipItem? {
        guard self.items.indices.contains(2) else { return nil }
        return self.items[2]
    }

    // MARK: - Lifecycle

    public init(url: URL, description: String?, items: [ClipItem], tags: [String], isHidden: Bool, registeredDate: Date, updatedDate: Date) {
        self.url = url
        self.description = description
        self.items = items.sorted(by: { $0.clipIndex < $1.clipIndex })
        self.tags = tags
        self.isHidden = isHidden
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate
    }

    // MARK: - Methods

    public func updating(tags: [String]) -> Self {
        return .init(url: self.url,
                     description: self.description,
                     items: self.items,
                     tags: tags,
                     isHidden: self.isHidden,
                     registeredDate: self.registeredDate,
                     updatedDate: self.updatedDate)
    }

    public func removedItem(at index: Int) -> Self {
        let newItems = self.items.enumerated()
            .filter { $0.offset != index }
            .map { $0.element }
        return .init(url: self.url,
                     description: self.description,
                     items: newItems,
                     tags: self.tags,
                     isHidden: self.isHidden,
                     registeredDate: self.registeredDate,
                     updatedDate: self.updatedDate)
    }
}

extension Clip: Identifiable {
    public typealias Identity = URL

    public var identity: URL {
        return self.url
    }
}

extension Clip: Hashable {}
