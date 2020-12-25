//
//  Copyright © 2020 Tasuku Tozawa. All rights reserved.
//

import UIKit

public protocol ClipInformationPresentedAnimatorDataSource {
    func animatingInformationView(_ animator: ClipInformationAnimator) -> ClipInformationView?

    func clipInformationAnimator(_ animator: ClipInformationAnimator, imageFrameOnContainerView containerView: UIView) -> CGRect
}
