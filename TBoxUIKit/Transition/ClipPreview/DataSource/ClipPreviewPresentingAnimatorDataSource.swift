//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ClipPreviewPresentingCell: UICollectionViewCell {
    func animatingImageView(at index: Int) -> UIImageView?
}

public protocol ClipPreviewPresentingAnimatorDataSource {
    func animatingCell(_ animator: ClipPreviewAnimator, shouldAdjust: Bool) -> ClipPreviewPresentingCell?
    func baseView(_ animator: ClipPreviewAnimator) -> UIView?
    func componentsOverBaseView(_ animator: ClipPreviewAnimator) -> [UIView]
    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView, forItemId itemId: ClipItem.Identity?) -> CGRect
    func animatingCellCornerRadius(_ animator: ClipPreviewAnimator) -> CGFloat
}
