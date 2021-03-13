//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

struct ClipPreviewPageBarState: Equatable {
    enum Alert: Equatable {
        case addition
        case deletion(includesRemoveFromClip: Bool)
        case share(data: [Data])
        case shareTargetSelection
        case error(String)
    }

    struct Item: Equatable {
        enum Kind: Equatable {
            case back
            case browse
            case add
            case share
            case delete
            case info
        }

        let kind: Kind
        let isEnabled: Bool
    }

    var parentState: ClipPreviewPageViewState
    var verticalSizeClass: UIUserInterfaceSizeClass

    var leftBarButtonItems: [Item]
    var rightBarButtonItems: [Item]
    var toolBarItems: [Item]

    var isToolBarHidden: Bool

    var alert: Alert?
}
