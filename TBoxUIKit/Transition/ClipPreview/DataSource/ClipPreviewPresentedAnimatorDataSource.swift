//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ClipPreviewPresentedAnimatorDataSource {
    var previewingClipId: Clip.Identity? { get }
    func animatingPreviewView(_ animator: ClipPreviewAnimator) -> ClipPreviewView?
    func isCurrentItemPrimary(_ animator: ClipPreviewAnimator) -> Bool
    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView) -> CGRect
}
