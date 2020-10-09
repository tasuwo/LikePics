//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

protocol ClipPreviewAnimatorDelegate: AnyObject {
    func didFailToPresent(_ animator: ClipPreviewAnimator)
    func didFailToDismiss(_ animator: ClipPreviewAnimator)
}

public protocol ClipPreviewAnimator {}
