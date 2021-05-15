//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

public struct ListingClip: Codable, Hashable {
    public struct Item: Codable, Equatable, Hashable {
        public let itemId: UUID
        public let imageId: UUID

        init(_ item: ClipItem) {
            self.itemId = item.id
            self.imageId = item.imageId
        }
    }

    public let id: UUID
    public let primaryImage: Item?
    public let secondaryItem: Item?
    public let tertiaryItem: Item?
    public let isHidden: Bool

    // MARK: Lifecycle

    public init(_ clip: Clip) {
        self.id = clip.id
        self.primaryImage = !clip.items.isEmpty ? .init(clip.items[0]) : nil
        self.secondaryItem = clip.items.count > 1 ? .init(clip.items[1]) : nil
        self.tertiaryItem = clip.items.count > 2 ? .init(clip.items[2]) : nil
        self.isHidden = clip.isHidden
    }
}

extension ListingClip: Equatable {
    // MARK: - Equatable

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
