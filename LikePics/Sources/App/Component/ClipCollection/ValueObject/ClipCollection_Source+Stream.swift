//
//  Copyright © 2022 Tasuku Tozawa. All rights reserved.
//

import Combine
import Domain

extension ClipCollection.Source {
    struct Stream {
        let clips: [Clip]
        let clipsStream: AnyPublisher<[Clip], Error>
        let description: String
        let query: Any
    }

    func fetchStream(by queryService: ClipQueryServiceProtocol) -> Stream {
        switch self {
        case .all:
            let query: ClipListQuery
            switch queryService.queryAllClips() {
            case let .success(result):
                query = result

            case let .failure(error):
                fatalError("Failed to load clips: \(error.localizedDescription)")
            }

            return Stream(clips: query.clips.value,
                          clipsStream: query.clips.eraseToAnyPublisher(),
                          description: L10n.clipCollectionViewTitleAll,
                          query: query)

        case let .album(albumId):
            let query: AlbumQuery
            switch queryService.queryAlbum(having: albumId) {
            case let .success(result):
                query = result

            case let .failure(error):
                fatalError("Failed to load clips: \(error.localizedDescription)")
            }

            return Stream(clips: query.album.value.clips,
                          clipsStream: query.album.map(\.clips).eraseToAnyPublisher(),
                          description: query.album.value.title,
                          query: query)

        case .uncategorized:
            let query: ClipListQuery
            switch queryService.queryUncategorizedClips() {
            case let .success(result):
                query = result

            case let .failure(error):
                fatalError("Failed to load clips: \(error.localizedDescription)")
            }

            return Stream(clips: query.clips.value,
                          clipsStream: query.clips.eraseToAnyPublisher(),
                          description: L10n.searchResultTitleUncategorized,
                          query: query)

        case let .tag(tag):
            let query: ClipListQuery
            switch queryService.queryClips(tagged: tag.id) {
            case let .success(result):
                query = result

            case let .failure(error):
                fatalError("Failed to load clips: \(error.localizedDescription)")
            }

            return Stream(clips: query.clips.value,
                          clipsStream: query.clips.eraseToAnyPublisher(),
                          description: tag.name,
                          query: query)

        case let .search(searchQuery):
            let query: ClipListQuery

            switch queryService.queryClips(query: searchQuery) {
            case let .success(result):
                query = result

            case let .failure(error):
                fatalError("Failed to load clips: \(error.localizedDescription)")
            }

            return Stream(clips: query.clips.value,
                          clipsStream: query.clips.eraseToAnyPublisher(),
                          description: searchQuery.displayTitle,
                          query: query)
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
