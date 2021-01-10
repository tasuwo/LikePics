//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import Domain
import UIKit

public protocol ClipPreviewPresentingAnimatorDataSource {
    func animatingCell(_ animator: ClipPreviewAnimator) -> ClipCollectionViewCell?
    func presentingView(_ animator: ClipPreviewAnimator) -> UIView?
    func componentsOverPresentingView(_ animator: ClipPreviewAnimator) -> [UIView]
    func clipPreviewAnimator(_ animator: ClipPreviewAnimator, frameOnContainerView containerView: UIView, forItemId itemId: ClipItem.Identity?) -> CGRect
}
