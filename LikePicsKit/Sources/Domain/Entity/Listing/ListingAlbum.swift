//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

// sourcery: AutoDefaultValuePublic
public struct ListingAlbum: Codable, Equatable, Hashable {
    public let id: UUID
    public let title: String
    public let isHidden: Bool
    public let registeredDate: Date
    public let updatedDate: Date

    // MARK: - Lifecycle

    public init(id: UUID,
                title: String,
                isHidden: Bool,
                registeredDate: Date,
                updatedDate: Date)
    {
        self.id = id
        self.title = title
        self.isHidden = isHidden
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate
    }
}

extension ListingAlbum: Identifiable {
    public typealias Identity = UUID

    public var identity: UUID {
        return id
    }
}
