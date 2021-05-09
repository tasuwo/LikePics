//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipCollectionNavigationBarState: Equatable {
    struct Item: Equatable {
        enum Kind: Equatable {
            enum Layout {
                case waterFall
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

extension ClipCollectionNavigationBarState {
    init(source: ClipCollection.Source) {
        self.source = source
        layout = .waterfall
        operation = .none
        rightItems = []
        leftItems = []
        clipCount = 0
        selectionCount = 0
    }
}
