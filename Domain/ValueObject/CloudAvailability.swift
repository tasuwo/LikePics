//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum CloudAvailability {
    case available(Context)
    case unavailable
    case unknown

    public enum Context {
        case none
        case accountChanged
    }

    var isAvailable: Bool {
        switch self {
        case .available:
            return true

        case .unavailable, .unknown:
            return false
        }
    }
}
