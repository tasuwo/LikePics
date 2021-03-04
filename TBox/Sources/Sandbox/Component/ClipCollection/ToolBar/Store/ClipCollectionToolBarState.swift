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
        case share(data: [Data])
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

    var source: ClipCollection.Source
    var operation: ClipCollection.Operation

    var items: [Item]
    var isHidden: Bool

    var _selections: [Clip.Identity: Set<ImageContainer.Identity>]

    var alert: Alert?
}
