//
//  Copyright © 2021 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ClipItemListPresenting {
    func animatingCell(_ animator: ClipItemListAnimator, id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool) -> ClipItemListPresentingCell?
    func animatingCellFrame(_ animator: ClipItemListAnimator, id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool, on containerView: UIView) -> CGRect
    func animatingCellCornerRadius(_ animator: ClipItemListAnimator) -> CGFloat
    func displayAnimatingCell(_ animator: ClipItemListAnimator, id: ClipPreviewPresentableCellIdentifier)
    func thumbnailFrame(_ animator: ClipItemListAnimator, id: ClipPreviewPresentableCellIdentifier, needsScroll: Bool, on containerView: UIView) -> CGRect
    func baseView(_ animator: ClipItemListAnimator) -> UIView?
    func componentsOverBaseView(_ animator: ClipItemListAnimator) -> [UIView]
}
