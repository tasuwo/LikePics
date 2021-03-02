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
            case reorder
            case done
        }

        let kind: Kind
        let isEnabled: Bool
    }

    struct Context: Equatable {
        let albumId: Album.Identity?

        var isAlbum: Bool {
            return albumId != nil
        }
    }

    var context: Context

    var rightItems: [Item]
    var leftItems: [Item]

    var clipCount: Int
    var selectionCount: Int
    var operation: ClipCollectionState.Operation
}
