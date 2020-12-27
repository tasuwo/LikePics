//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

extension ClipCollection {
    enum Operation {
        case none
        case selecting
        case reordering

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

            case .selecting, .reordering:
                return true
            }
        }
    }
}
