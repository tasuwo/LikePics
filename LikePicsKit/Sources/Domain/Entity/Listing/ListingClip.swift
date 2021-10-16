//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

public struct ListingClip: Codable, Hashable {
    public let id: UUID
    public let itemsCount: Int
    public let isHidden: Bool

    public init(id: UUID, itemsCount: Int, isHidden: Bool) {
        self.id = id
        self.itemsCount = itemsCount
        self.isHidden = isHidden
    }
}

extension ListingClip: Identifiable {
    public typealias Identity = UUID

    public var identity: UUID {
        return self.id
    }
}
