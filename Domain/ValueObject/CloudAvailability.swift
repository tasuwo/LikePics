//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum CloudAvailability: Equatable {
    case available(Context)
    case unavailable
    case unknown

    public enum Context: Equatable {
        case none
        case accountChanged
    }

    public var isAvailable: Bool {
        switch self {
        case .available:
            return true

        case .unavailable, .unknown:
            return false
        }
    }
}
