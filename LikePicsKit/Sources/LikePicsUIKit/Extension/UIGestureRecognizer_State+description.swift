//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

public extension UIGestureRecognizer.State {
    var description: String {
        switch self {
        case .possible:
            return "possible"

        case .began:
            return "began"

        case .changed:
            return "changed"

        case .ended:
            return "ended"

        case .cancelled:
            return "cancelled"

        case .failed:
            return "failed"

        @unknown default:
            return "unknown"
        }
    }
}