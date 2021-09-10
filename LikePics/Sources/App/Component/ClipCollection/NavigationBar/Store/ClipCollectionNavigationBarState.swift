//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipCollectionNavigationBarState: Equatable {
    struct Item: Equatable {
        enum Kind: Equatable {
            enum Layout: String {
                case waterFall = "water_fall"
                case grid
            }

            case cancel
            case selectAll
            case deselectAll
            case select
            case layout(Layout)
        }

        let kind: Kind
        let isEnabled: Bool
    }

    var source: ClipCollection.Source
    var layout: ClipCollection.Layout
    var operation: ClipCollection.Operation

    var rightItems: [Item]
    var leftItems: [Item]

    var clipCount: Int
    var selectionCount: Int
}

// MARK: - Codable

extension ClipCollectionNavigationBarState.Item: Codable {}

extension ClipCollectionNavigationBarState.Item.Kind.Layout: Codable {}

extension ClipCollectionNavigationBarState.Item.Kind: Codable {
    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case cancel
        case selectAll
        case deselectAll
        case select
        case layout
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .cancel:
            self = .cancel

        case .selectAll:
            self = .selectAll

        case .deselectAll:
            self = .deselectAll

        case .select:
            self = .select

        case .layout:
            let layout = try container.decode(Layout.self, forKey: .layout)
            self = .layout(layout)

        default:
            throw DecodingError.dataCorrupted(.init(codingPath: container.codingPath, debugDescription: "Unable to decode"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .cancel:
            try container.encode(true, forKey: .cancel)

        case .selectAll:
            try container.encode(true, forKey: .selectAll)

        case .deselectAll:
            try container.encode(true, forKey: .deselectAll)

        case .select:
            try container.encode(true, forKey: .select)

        case let .layout(layout):
            try container.encode(layout, forKey: .layout)
        }
    }
}
