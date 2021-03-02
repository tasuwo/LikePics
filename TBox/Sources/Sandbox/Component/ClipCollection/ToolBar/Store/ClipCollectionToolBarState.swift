//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import Domain

struct ClipCollectionToolBarState: Equatable {
    enum Alert: Equatable {
        case addition
        case changeVisibility
        case deletion(includesRemoveFromAlbum: Bool)
    }

    struct Item: Equatable {
        enum Kind: Equatable {
            case add
            case changeVisibility
            case share
            case delete
            case merge
        }

        let kind: Kind
        let isEnabled: Bool
    }

    struct Context: Equatable {
        var albumId: Album.Identity?

        var isAlbum: Bool {
            return albumId != nil
        }
    }

    var context: Context

    var items: [Item]
    var isHidden: Bool

    var _targetCount: Int
    var _operation: ClipCollectionState.Operation

    var alert: Alert?
}
