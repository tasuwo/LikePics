//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

enum Intent {
    case seeHome(ClipCollectionViewRootState)
    case seeSearch(SearchViewRootState)
    case seeSetting(SettingsViewState)
    case seeAlbumList(AlbumListViewState)
    case seeTagCollection(TagCollectionViewState)
}

extension Intent {
    var clipCollectionViewRootState: ClipCollectionViewRootState? {
        guard case let .seeHome(state) = self else { return nil }
        return state
    }

    var searchViewState: SearchViewRootState? {
        guard case let .seeSearch(state) = self else { return nil }
        return state
    }

    var settingsViewState: SettingsViewState? {
        guard case let .seeSetting(state) = self else { return nil }
        return state
    }

    var albumLitViewState: AlbumListViewState? {
        guard case let .seeAlbumList(state) = self else { return nil }
        return state
    }

    var tagCollectionViewState: TagCollectionViewState? {
        guard case let .seeTagCollection(state) = self else { return nil }
        return state
    }
}

extension Intent: Codable {
    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case seeHome
        case seeSearch
        case seeSetting
        case seeAlbumList
        case seeTagCollection
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .seeHome:
            let state = try container.decode(ClipCollectionViewRootState.self, forKey: .seeHome)
            self = .seeHome(state)

        case .seeSearch:
            let state = try container.decode(SearchViewRootState.self, forKey: .seeSearch)
            self = .seeSearch(state)

        case .seeSetting:
            let state = try container.decode(SettingsViewState.self, forKey: .seeSetting)
            self = .seeSetting(state)

        case .seeAlbumList:
            let state = try container.decode(AlbumListViewState.self, forKey: .seeAlbumList)
            self = .seeAlbumList(state)

        case .seeTagCollection:
            let state = try container.decode(TagCollectionViewState.self, forKey: .seeTagCollection)
            self = .seeTagCollection(state)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .seeHome(state):
            try container.encode(state, forKey: .seeHome)

        case let .seeSearch(state):
            try container.encode(state, forKey: .seeSearch)

        case let .seeSetting(state):
            try container.encode(state, forKey: .seeSetting)

        case let .seeAlbumList(state):
            try container.encode(state, forKey: .seeAlbumList)

        case let .seeTagCollection(state):
            try container.encode(state, forKey: .seeTagCollection)
        }
    }
}
