//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

struct ClipItemListToolBarState: Equatable {
    enum Alert: Equatable {
        case deletion(targetCount: Int)
        case editUrl
        case share(imageIds: [ImageContainer.Identity], targetCount: Int)
    }

    struct Item: Equatable {
        enum Kind: String, Equatable {
            case editUrl
            case share
            case delete
        }

        let kind: Kind
        let isEnabled: Bool
    }

    var items: [Item]
    var alert: Alert?

    var selectedItems: Set<ClipItem>
}

extension ClipItemListToolBarState {
    init() {
        items = []
        alert = nil
        selectedItems = .init()
    }
}
