//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipPreviewPresentedAnimatorDataSource {
    func animatingPage(_ animator: ClipPreviewAnimator) -> ClipPreviewView?

    func currentIndex(_ animator: ClipPreviewAnimator) -> Int?

    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView) -> CGRect
}
