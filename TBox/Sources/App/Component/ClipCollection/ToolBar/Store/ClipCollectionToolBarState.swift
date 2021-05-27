//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipCollectionToolBarState: Equatable {
    enum Alert: Equatable {
        case addition(targetCount: Int)
        case changeVisibility(targetCount: Int)
        case chooseDeletionType
        case deletion(targetCount: Int)
        case share(imageIds: [ImageContainer.Identity], targetCount: Int)
    }

    struct Item: Equatable {
        enum Kind: String, Equatable {
            case add
            case changeVisibility = "change_visibility"
            case share
            case delete
            case merge
        }

        let kind: Kind
        let isEnabled: Bool
    }

    var source: ClipCollection.Source
    var operation: ClipCollection.Operation

    var items: [Item]
    var isHidden: Bool

    var parentState: ClipCollectionState

    var alert: Alert?
}

// MARK: - Codable

extension ClipCollectionToolBarState.Item: Codable {}

extension ClipCollectionToolBarState.Item.Kind: Codable {}

extension ClipCollectionToolBarState.Alert: Codable {
    enum CodingKeys: CodingKey {
        case addition
        case changeVisibility
        case chooseDeletionType
        case deletion
        case share
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .addition:
            let targetCount = try container.decode(Int.self, forKey: .addition)
            self = .addition(targetCount: targetCount)

        case .changeVisibility:
            let targetCount = try container.decode(Int.self, forKey: .changeVisibility)
            self = .changeVisibility(targetCount: targetCount)

        case .chooseDeletionType:
            self = .chooseDeletionType

        case .deletion:
            let targetCount = try container.decode(Int.self, forKey: .deletion)
            self = .deletion(targetCount: targetCount)

        case .share:
            var nestedContainer = try container.nestedUnkeyedContainer(forKey: .share)
            let imageIds = try nestedContainer.decode([ImageContainer.Identity].self)
            let targetCount = try nestedContainer.decode(Int.self)
            self = .share(imageIds: imageIds, targetCount: targetCount)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case let .addition(targetCount: targetCount):
            try container.encode(targetCount, forKey: .addition)

        case let .changeVisibility(targetCount: targetCount):
            try container.encode(targetCount, forKey: .changeVisibility)

        case .chooseDeletionType:
            try container.encode(true, forKey: .chooseDeletionType)

        case let .deletion(targetCount: targetCount):
            try container.encode(targetCount, forKey: .deletion)

        case let .share(imageIds: imageIds, targetCount: targetCount):
            var nestedContainer = container.nestedUnkeyedContainer(forKey: .share)
            try nestedContainer.encode(imageIds)
            try nestedContainer.encode(targetCount)
        }
    }
}
