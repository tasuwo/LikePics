//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

extension AlbumList {
    enum NavigationItem {
        case add(isEnabled: Bool)
        case edit(isEnabled: Bool)
        case done

        var isEnabled: Bool {
            switch self {
            case let .add(isEnabled):
                return isEnabled

            case let .edit(isEnabled):
                return isEnabled

            default:
                return true
            }
        }
    }
}
