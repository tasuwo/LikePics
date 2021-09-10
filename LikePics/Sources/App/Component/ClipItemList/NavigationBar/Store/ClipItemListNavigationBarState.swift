//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

struct ClipItemListNavigationBarState: Equatable {
    struct Item: Equatable {
        enum Kind: Equatable {
            case resume
            case select
            case cancel
        }

        let kind: Kind
        let isEnabled: Bool
    }

    var rightItems: [Item]
    var leftItems: [Item]

    var isEditing: Bool
    var selectionCount: Int
}

extension ClipItemListNavigationBarState {
    init() {
        rightItems = []
        leftItems = []
        isEditing = false
        selectionCount = 0
    }
}
