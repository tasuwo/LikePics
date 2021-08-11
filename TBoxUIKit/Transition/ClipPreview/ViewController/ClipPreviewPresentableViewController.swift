//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ClipPreviewPresentableCell: UICollectionViewCell {
    func thumbnail() -> UIImageView
}

public protocol ClipPreviewPresentableViewController {
    func animatingCell(_ animator: ClipPreviewAnimator, id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool) -> ClipPreviewPresentableCell?
    func animatingCellFrame(_ animator: ClipPreviewAnimator, id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool, on containerView: UIView) -> CGRect
    func animatingCellCornerRadius(_ animator: ClipPreviewAnimator) -> CGFloat
    func displayAnimatingCell(_ animator: ClipPreviewAnimator, id: ClipPreviewPresentableCellIdentifier)
    func thumbnailFrame(_ animator: ClipPreviewAnimator, id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool, on containerView: UIView) -> CGRect
    func baseView(_ animator: ClipPreviewAnimator) -> UIView?
    func componentsOverBaseView(_ animator: ClipPreviewAnimator) -> [UIView]
    func isDisplayablePrimaryThumbnailOnly(_ animator: ClipPreviewAnimator) -> Bool
}
