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

    struct Context: Equatable {
        var albumId: Album.Identity?

        var isAlbum: Bool {
            return albumId != nil
        }
    }

    let context: Context

    let items: [Item]
    let isHidden: Bool

    let _targetCount: Int
    let _operation: ClipCollectionState.Operation

    let alert: Alert?
}

extension ClipCollectionToolBarState {
    func updating(alert: Alert?) -> Self {
        return .init(context: context,
                     items: items,
                     isHidden: isHidden,
                     _targetCount: _targetCount,
                     _operation: _operation,
                     alert: alert)
    }

    func updating(targetCount: Int) -> Self {
        return .init(context: context,
                     items: items,
                     isHidden: isHidden,
                     _targetCount: targetCount,
                     _operation: _operation,
                     alert: alert)
    }

    func updating(operation: ClipCollectionState.Operation) -> Self {
        return .init(context: context,
                     items: items,
                     isHidden: isHidden,
                     _targetCount: _targetCount,
                     _operation: operation,
                     alert: alert)
    }

    func updating(isHidden: Bool) -> Self {
        return .init(context: context,
                     items: items,
                     isHidden: isHidden,
                     _targetCount: _targetCount,
                     _operation: _operation,
                     alert: alert)
    }

    func updating(items: [Item]) -> Self {
        return .init(context: context,
                     items: items,
                     isHidden: isHidden,
                     _targetCount: _targetCount,
                     _operation: _operation,
                     alert: alert)
    }
}
