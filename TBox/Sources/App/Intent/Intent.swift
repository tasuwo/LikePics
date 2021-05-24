//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

enum Intent {
    case clips(ClipCollectionViewRootState, preview: Clip.Identity?)
    case search(SearchViewRootState)
    case setting(SettingsViewState)
    case albums(AlbumListViewState)
    case tags(TagCollectionViewState)
}

extension Intent {
    var homeViewState: ClipCollectionViewRootState? {
        guard case let .clips(state, _) = self, case .all = state.clipCollectionState.source else { return nil }
        return state
    }

    var searchViewState: SearchViewRootState? {
        guard case let .search(state) = self else { return nil }
        return state
    }

    var settingsViewState: SettingsViewState? {
        guard case let .setting(state) = self else { return nil }
        return state
    }

    var albumLitViewState: AlbumListViewState? {
        guard case let .albums(state) = self else { return nil }
        return state
    }

    var tagCollectionViewState: TagCollectionViewState? {
        guard case let .tags(state) = self else { return nil }
        return state
    }
}

extension Intent: Codable {
    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case clips
        case search
        case setting
        case albums
        case tags
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .clips:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .clips)
            let state = try nestedContainer.decode(ClipCollectionViewRootState.self)
            let clipId = try nestedContainer.decodeIfPresent(Clip.Identity.self)
            self = .clips(state, preview: clipId)

        case .search:
            let state = try container.decode(SearchViewRootState.self, forKey: .search)
            self = .search(state)

        case .setting:
            let state = try container.decode(SettingsViewState.self, forKey: .setting)
            self = .setting(state)

        case .albums:
            let state = try container.decode(AlbumListViewState.self, forKey: .albums)
            self = .albums(state)

        case .tags:
            let state = try container.decode(TagCollectionViewState.self, forKey: .tags)
            self = .tags(state)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .clips(state, preview: clipId):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .clips)
            try nestedContainer.encode(state)
            try nestedContainer.encode(clipId)

        case let .search(state):
            try container.encode(state, forKey: .search)

        case let .setting(state):
            try container.encode(state, forKey: .setting)

        case let .albums(state):
            try container.encode(state, forKey: .albums)

        case let .tags(state):
            try container.encode(state, forKey: .tags)
        }
    }
}
