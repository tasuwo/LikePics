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

    let context: Context

    let rightItems: [Item]
    let leftItems: [Item]

    let clipCount: Int
    let selectionCount: Int
    let operation: ClipCollectionState.Operation
}

extension ClipCollectionNavigationBarState {
    func updating(rightItems: [Item],
                  leftItems: [Item]) -> Self
    {
        return .init(context: context,
                     rightItems: rightItems,
                     leftItems: leftItems,
                     clipCount: clipCount,
                     selectionCount: selectionCount,
                     operation: operation)
    }

    func updating(clipCount: Int) -> Self {
        return .init(context: context,
                     rightItems: rightItems,
                     leftItems: leftItems,
                     clipCount: clipCount,
                     selectionCount: selectionCount,
                     operation: operation)
    }

    func updating(selectionCount: Int) -> Self {
        return .init(context: context,
                     rightItems: rightItems,
                     leftItems: leftItems,
                     clipCount: clipCount,
                     selectionCount: selectionCount,
                     operation: operation)
    }

    func updating(operation: ClipCollectionState.Operation) -> Self {
        return .init(context: context,
                     rightItems: rightItems,
                     leftItems: leftItems,
                     clipCount: clipCount,
                     selectionCount: selectionCount,
                     operation: operation)
    }
}
