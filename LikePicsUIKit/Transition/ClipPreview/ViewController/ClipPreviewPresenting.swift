//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ClipPreviewPresenting {
    func previewingClipItem(_ animator: ClipPreviewAnimator) -> PreviewingClipItem?
    func previewView(_ animator: ClipPreviewAnimator) -> ClipPreviewView?
    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect
}
