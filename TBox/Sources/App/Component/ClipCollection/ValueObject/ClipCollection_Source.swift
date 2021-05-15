//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipCollection {
    enum Source: Equatable {
        case all
        case album(Album.Identity)
        case tag(Tag)
        case uncategorized
        case search(ClipSearchQuery)

        var isAlbum: Bool {
            switch self {
            case .album:
                return true

            default:
                return false
            }
        }
    }
}

// MARK: - Codable

extension ClipCollection.Source: Codable {
    enum CodingKeys: CodingKey {
        case all
        case album
        case tag
        case uncategorized
        case search
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .all:
            self = .all

        case .album:
            let albumId = try container.decode(Album.Identity.self, forKey: .album)
            self = .album(albumId)

        case .tag:
            let tag = try container.decode(Tag.self, forKey: .tag)
            self = .tag(tag)

        case .uncategorized:
            self = .uncategorized

        case .search:
            let query = try container.decode(ClipSearchQuery.self, forKey: .search)
            self = .search(query)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .all:
            try container.encode(true, forKey: .all)

        case let .album(albumId):
            try container.encode(albumId, forKey: .album)

        case let .tag(tag):
            try container.encode(tag, forKey: .tag)

        case .uncategorized:
            try container.encode(true, forKey: .uncategorized)

        case let .search(query):
            try container.encode(query, forKey: .search)
        }
    }
}
