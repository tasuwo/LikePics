//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import UIKit

extension UIGestureRecognizer.State {
    var isContinuousGestureFinished: Bool {
        switch self {
        case .possible, .began, .changed:
            return false

        case .failed, .ended, .cancelled, .recognized:
            return true

        @unknown default:
            return false
        }
    }
}
