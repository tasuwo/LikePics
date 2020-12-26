//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

extension ClipCollection {
    struct ToolBarItem {
        enum Kind {
            case add
            case delete
            case removeFromAlbum
            case hide
            case unhide
            case share
            case merge
        }

        let kind: Kind
        let isEnabled: Bool
    }
}
