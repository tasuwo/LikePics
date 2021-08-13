//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ClipItemListPresentable {
    func previewingClipItem(_ animator: ClipItemListAnimator) -> PreviewingClipItem?
    func previewView(_ animator: ClipItemListAnimator) -> ClipPreviewView?
    func clipItemListAnimator(_ animator: ClipItemListAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect
}
