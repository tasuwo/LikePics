//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ClipPreviewViewController {
    func previewingClipItem(_ animator: ClipPreviewAnimator) -> PreviewingClipItem?
    func animatingPreviewView(_ animator: ClipPreviewAnimator) -> ClipPreviewView?
    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView) -> CGRect
}
