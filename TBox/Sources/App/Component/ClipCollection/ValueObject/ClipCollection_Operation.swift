//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain

extension ClipCollection {
    enum Operation: Equatable {
        case none
        case selecting

        var isAllowedMultipleSelection: Bool {
            switch self {
            case .selecting:
                return true

            default:
                return false
            }
        }

        var isEditing: Bool {
            switch self {
            case .none:
                return false

            case .selecting:
                return true
            }
        }
    }
}
