//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Foundation

// sourcery: AutoDefaultValue, AutoDefaultValueUsePublic
public struct ListingAlbumTitle: Codable, Equatable, Hashable {
    public let id: UUID
    public let title: String
    public let isHidden: Bool
    public let registeredDate: Date
    public let updatedDate: Date

    private let _searchableTitle: String?

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

        self._searchableTitle = title.transformToSearchableText()
    }

    public init(id: UUID,
                title: String,
                isHidden: Bool,
                registeredDate: Date,
                updatedDate: Date,
                _searchableTitle: String?)
    {
        self.id = id
        self.title = title
        self.isHidden = isHidden
        self.registeredDate = registeredDate
        self.updatedDate = updatedDate
        self._searchableTitle = _searchableTitle
    }

    public init(_ album: Album) {
        self.id = album.id
        self.title = album.title
        self.isHidden = album.isHidden
        self.registeredDate = album.registeredDate
        self.updatedDate = album.updatedDate
        self._searchableTitle = album.searchableText
    }
}

extension ListingAlbumTitle: Identifiable {
    public typealias Identity = UUID

    public var identity: UUID {
        return id
    }
}

extension ListingAlbumTitle: Searchable {
    public var searchableText: String? { _searchableTitle }
}
