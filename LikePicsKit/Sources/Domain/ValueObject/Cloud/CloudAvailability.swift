//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

public enum CloudAvailability: Equatable, Codable {
    case available
    case unavailable

    public var isAvailable: Bool {
        switch self {
        case .available:
            return true

        case .unavailable:
            return false
        }
    }
}
