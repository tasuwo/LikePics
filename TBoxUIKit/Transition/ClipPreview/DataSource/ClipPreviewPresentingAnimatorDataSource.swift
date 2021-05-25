//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ClipPreviewPresentingCell: UICollectionViewCell {
    func primaryThumbnailImageView() -> UIImageView
}

public protocol ClipPreviewPresentingAnimatorDataSource {
    func animatingCell(_ animator: ClipPreviewAnimator, clipId: Clip.Identity, needsScroll: Bool) -> ClipPreviewPresentingCell?
    func animatingCellFrame(_ animator: ClipPreviewAnimator, clipId: Clip.Identity, needsScroll: Bool, on containerView: UIView) -> CGRect
    func animatingCellCornerRadius(_ animator: ClipPreviewAnimator) -> CGFloat
    func displayAnimatingCell(_ animator: ClipPreviewAnimator, clipId: Clip.Identity)
    func primaryThumbnailFrame(_ animator: ClipPreviewAnimator, clipId: Clip.Identity, needsScroll: Bool, on containerView: UIView) -> CGRect
    func baseView(_ animator: ClipPreviewAnimator) -> UIView?
    func componentsOverBaseView(_ animator: ClipPreviewAnimator) -> [UIView]
}
