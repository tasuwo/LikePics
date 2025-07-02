//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

extension ClipCollection {
    public enum Operation: String, Codable, Equatable {
        case none
        case selecting

        public var isAllowedMultipleSelection: Bool {
            switch self {
            case .selecting:
                return true

            default:
                return false
            }
        }

        public var isEditing: Bool {
            switch self {
            case .none:
                return false

            case .selecting:
                return true
            }
        }
    }
}
