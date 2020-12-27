//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

extension ClipCollection {
    enum NavigationItem {
        case cancel
        case selectAll
        case deselectAll
        case select(isEnabled: Bool)
        case reorder(isEnabled: Bool)
        case done

        var isEnabled: Bool {
            switch self {
            case let .select(isEnabled):
                return isEnabled

            case let .reorder(isEnabled):
                return isEnabled

            default:
                return true
            }
        }
    }
}
