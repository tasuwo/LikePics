//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

// swiftlint:disable identifier_name

import Domain

struct ClipCollectionToolBarState: Equatable {
    enum Alert: Equatable {
        case addition(targetCount: Int)
        case changeVisibility(targetCount: Int)
        case deletion(includesRemoveFromAlbum: Bool, targetCount: Int)
        case share(items: [ClipItemImageShareItem], targetCount: Int)
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

    var parentState: ClipCollectionState

    var alert: Alert?
}
