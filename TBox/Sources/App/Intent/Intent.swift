//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

enum Intent {
    case seeSetting(SettingsViewState)
    case seeAlbumList(AlbumListViewState)
}

extension Intent {
    var settingsViewState: SettingsViewState? {
        guard case let .seeSetting(state) = self else { return nil }
        return state
    }

    var albumLitViewState: AlbumListViewState? {
        guard case let .seeAlbumList(state) = self else { return nil }
        return state
    }
}

extension Intent: Codable {
    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case seeSetting
        case seeAlbumList
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .seeSetting:
            let state = try container.decode(SettingsViewState.self, forKey: .seeSetting)
            self = .seeSetting(state)

        case .seeAlbumList:
            let state = try container.decode(AlbumListViewState.self, forKey: .seeAlbumList)
            self = .seeAlbumList(state)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .seeSetting(state):
            try container.encode(state, forKey: .seeSetting)

        case let .seeAlbumList(state):
            try container.encode(state, forKey: .seeAlbumList)
        }
    }
}
