//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public struct Clip {
    public let url: URL
    public let description: String?
    public let items: [ClipItem]
    public let registeredDate: Date
    public let updatedDate: Date

    public var primaryItem: ClipItem? {
        return self.items.first(where: { $0.clipIndex == 0 })
    }

    public var secondaryItem: ClipItem? {
        return self.items.first(where: { $0.clipIndex == 1 })
    }

    public var tertiaryItem: ClipItem? {
        return self.items.first(where: { $0.clipIndex == 2 })
    }

    // MARK: - Lifecycle

    public init(url: URL, description: String?, items: [ClipItem], registeredDate: Date, updatedDate: Date) {
        self.url = url
        self.description = description
        self.items = items
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate
    }
}
