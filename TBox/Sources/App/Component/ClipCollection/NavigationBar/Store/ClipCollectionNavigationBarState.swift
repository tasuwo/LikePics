//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipCollectionNavigationBarState: Equatable {
    struct Item: Equatable {
        enum Kind: Equatable {
            case cancel
            case selectAll
            case deselectAll
            case select
        }

        let kind: Kind
        let isEnabled: Bool
    }

    var source: ClipCollection.Source
    var operation: ClipCollection.Operation

    var rightItems: [Item]
    var leftItems: [Item]

    var clipCount: Int
    var selectionCount: Int
}
