//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

extension AlbumList {
    enum Operation {
        case none
        case editing

        var isEditing: Bool {
            switch self {
            case .none:
                return false

            case .editing:
                return true
            }
        }
    }
}
