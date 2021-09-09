//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import Domain

struct AlbumListViewState: Equatable, Codable {
    enum Alert: Equatable {
        case error(String?)
        case addition
        case renaming(albumId: Album.Identity, title: String)
        case deletion(albumId: Album.Identity, title: String)
    }

    var searchQuery: String
    var searchStorage: SearchableStorage<Album>
    var albums: EntityCollectionSnapshot<Album>

    var isPreparedQueryEffects: Bool

    var isEditing: Bool
    var isEmptyMessageViewDisplaying: Bool
    var isCollectionViewDisplaying: Bool
    var isSearchBarEnabled: Bool
    var isAddButtonEnabled: Bool
    var isDragInteractionEnabled: Bool
    var isSomeItemsHidden: Bool

    var alert: Alert?
}

extension AlbumListViewState {
    init(isSomeItemsHidden: Bool) {
        searchQuery = ""
        searchStorage = .init()
        albums = .init()

        isPreparedQueryEffects = false

        isEditing = false
        isEmptyMessageViewDisplaying = false
        isCollectionViewDisplaying = false
        isSearchBarEnabled = false
        isAddButtonEnabled = true
        isDragInteractionEnabled = false

        alert = nil
        self.isSomeItemsHidden = isSomeItemsHidden
    }
}

extension AlbumListViewState {
    var isEditButtonEnabled: Bool {
        !albums.filteredEntities().isEmpty
    }

    var filteredOrderedAlbums: Set<Ordered<Album>> {
        let albums = albums
            .filteredOrderedEntities()
            .map { Ordered(index: $0.index, value: isSomeItemsHidden ? $0.value.removingHiddenClips() : $0.value) }
        return Set(albums)
    }

    var orderedFilteredAlbums: [Album] {
        albums
            .orderedFilteredEntities()
            .map { isSomeItemsHidden ? $0.removingHiddenClips() : $0 }
    }

    var emptyMessageViewAlpha: CGFloat {
        isEmptyMessageViewDisplaying ? 1 : 0
    }

    var collectionViewAlpha: CGFloat {
        isCollectionViewDisplaying ? 1 : 0
    }
}

extension AlbumListViewState {
    func removingSessionStates() -> Self {
        var state = self
        state.searchStorage = .init()
        state.albums = state.albums
            .updated(entities: [])
            .updated(filteredIds: .init())
        state.alert = nil
        state.isPreparedQueryEffects = false
        return state
    }
}

extension AlbumListViewState.Alert: Codable {
    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case error
        case addition
        case renaming
        case deletion
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .error:
            let message = try container.decodeIfPresent(String.self, forKey: .error)
            self = .error(message)

        case .addition:
            self = .addition

        case .renaming:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .renaming)
            let albumId = try nestedContainer.decode(Album.Identity.self)
            let title = try nestedContainer.decode(String.self)
            self = .renaming(albumId: albumId, title: title)

        case .deletion:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .deletion)
            let albumId = try nestedContainer.decode(Album.Identity.self)
            let title = try nestedContainer.decode(String.self)
            self = .deletion(albumId: albumId, title: title)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .error(message):
            try container.encode(message, forKey: .error)

        case .addition:
            try container.encode(true, forKey: .addition)

        case let .renaming(albumId: albumId, title: title):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .renaming)
            try nestedContainer.encode(albumId)
            try nestedContainer.encode(title)

        case let .deletion(albumId: albumId, title: title):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .deletion)
            try nestedContainer.encode(albumId)
            try nestedContainer.encode(title)
        }
    }
}
