//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ClipPreviewPresentedAnimatorDataSource {
    func animatingPage(_ animator: ClipPreviewAnimator) -> ClipPreviewView?
    func currentItemId(_ animator: ClipPreviewAnimator) -> ClipItem.Identity?
    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView) -> CGRect
}
