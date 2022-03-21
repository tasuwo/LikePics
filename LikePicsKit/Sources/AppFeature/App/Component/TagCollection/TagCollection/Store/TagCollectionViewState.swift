//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import CoreGraphics
import Domain

public struct TagCollectionViewState: Equatable {
    enum Alert: Equatable {
        case error(String?)
        case edit(tagId: Tag.Identity, name: String)
        case deletion(tagId: Tag.Identity, tagName: String)
        case addition
    }

    var tags: EntityCollectionSnapshot<Tag>
    var searchQuery: String
    var searchStorage: SearchableStorage<Tag>

    var isPreparedQueryEffects: Bool

    var isCollectionViewHidden: Bool
    var isEmptyMessageViewHidden: Bool
    var isSearchBarEnabled: Bool
    var isSomeItemsHidden: Bool

    var alert: Alert?
}

extension TagCollectionViewState {
    init(isSomeItemsHidden: Bool) {
        tags = .init()
        searchQuery = ""
        searchStorage = .init()

        isPreparedQueryEffects = false

        isCollectionViewHidden = true
        isEmptyMessageViewHidden = true
        isSearchBarEnabled = false
        self.isSomeItemsHidden = isSomeItemsHidden

        alert = nil
    }
}

extension TagCollectionViewState {
    var emptyMessageViewAlpha: CGFloat {
        isEmptyMessageViewHidden ? 0 : 1
    }
}

extension TagCollectionViewState {
    func removingSessionStates() -> Self {
        var state = self
        state.tags = state.tags
            .updated(entities: [])
            .updated(filteredIds: .init())
        state.searchStorage = .init()
        state.alert = nil
        state.isPreparedQueryEffects = false
        return state
    }
}

// MARK: - Codable

extension TagCollectionViewState: Codable {}

extension TagCollectionViewState.Alert: Codable {
    enum CodingKeys: CodingKey {
        case error
        case addition
        case edit
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

        case .edit:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .edit)
            let tagId = try nestedContainer.decode(Tag.Identity.self)
            let name = try nestedContainer.decode(String.self)
            self = .edit(tagId: tagId, name: name)

        case .deletion:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .deletion)
            let tagId = try nestedContainer.decode(Tag.Identity.self)
            let tagName = try nestedContainer.decode(String.self)
            self = .deletion(tagId: tagId, tagName: tagName)

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

        case let .edit(tagId: tagId, name: name):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .edit)
            try nestedContainer.encode(tagId)
            try nestedContainer.encode(name)

        case let .deletion(tagId: tagId, tagName: tagName):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .deletion)
            try nestedContainer.encode(tagId)
            try nestedContainer.encode(tagName)
        }
    }
}
